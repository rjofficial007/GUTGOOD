import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/food_image.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Registry for deduplicated food photos (audit §E).
///
/// Owns `user_profiles/{uid}/food_images/{sha256_16}`: registration, link
/// tracking (which chat/scan/meal/symptom docs reference a photo), and
/// thumbnail-URL resolution for display. All methods are failure-tolerant
/// (log-and-continue): the registry must never break a user turn.
abstract class FoodImageService {
  /// Creates the doc on first upload, refreshes URL/meta on re-upload.
  /// Never touches links/linkCount/createdAt on existing docs.
  Future<void> registerImage({required String hash, required String storagePath, required String downloadUrl, int? bytes});

  /// Adds/removes a link transactionally (self-heals a missing doc on add).
  Future<void> addLink({required String hash, required String kind, required String id});
  Future<void> removeLink({required String hash, required String kind, required String id});

  Future<FoodImage?> getByHash(String hash);

  /// Best display URL for a photo: server thumbnail when known, else the
  /// full URL. Only genuine thumbs are cached — fallbacks are never cached,
  /// so a thumb that lands later is picked up on the next resolve.
  Future<String> resolveThumbUrl({required String fullUrl, String? hash});
}

class FoodImageServiceImpl implements FoodImageService {
  FoodImageServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db, required SharedPreferences prefs}) : _auth = auth, _db = db, _prefs = prefs;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final SharedPreferences _prefs;

  static const _thumbCacheKey = 'food_image_thumb_cache_v1';
  static const _thumbCacheCap = 200;

  final Map<String, String> _thumbMem = {};

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _col {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('user_profiles').doc(uid).collection('food_images');
  }

  String _derivedPath(String uid, String hash) => 'users/$uid/food_images/$hash.jpg';

  @override
  Future<void> registerImage({required String hash, required String storagePath, required String downloadUrl, int? bytes}) async {
    final col = _col;
    if (col == null || hash.isEmpty) return;
    try {
      final ref = col.doc(hash);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          tx.set(ref, {
            'hash': hash,
            'storagePath': storagePath,
            'downloadUrl': downloadUrl,
            'bytes': ?bytes,
            'links': const FoodImageLinks().toMap(),
            'linkCount': 0,
            'foods': const [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(ref, {'storagePath': storagePath, 'downloadUrl': downloadUrl, 'bytes': ?bytes, 'updatedAt': FieldValue.serverTimestamp()});
        }
      });
    } catch (e) {
      AppLogger.firestore('FoodImageService: register failed', error: e);
    }
  }

  @override
  Future<void> addLink({required String hash, required String kind, required String id}) async {
    await _modifyLinks(hash, kind, id, add: true);
  }

  @override
  Future<void> removeLink({required String hash, required String kind, required String id}) async {
    await _modifyLinks(hash, kind, id, add: false);
  }

  Future<void> _modifyLinks(String hash, String kind, String id, {required bool add}) async {
    final col = _col;
    final uid = _uid;
    if (col == null || uid == null || hash.isEmpty || id.isEmpty) return;
    try {
      final ref = col.doc(hash);
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) {
          if (!add) return;
          // Self-heal: a link for an unregistered photo (e.g. the storage
          // layer's best-effort register failed) creates a minimal doc
          // rather than dropping the link. The thumbnail function backfills
          // the rest when it processes the object.
          final links = const FoodImageLinks().addLink(kind, id);
          tx.set(ref, {
            'hash': hash,
            'storagePath': _derivedPath(uid, hash),
            'links': links.toMap(),
            'linkCount': links.total,
            'foods': const [],
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return;
        }
        final current = FoodImageLinks.fromMap((snap.data()!['links']) as Map<String, dynamic>?);
        final next = add ? current.addLink(kind, id) : current.removeLink(kind, id);
        if (next == current) return; // idempotent: no count drift on re-link/miss
        tx.update(ref, {
          'links': next.toMap(),
          'linkCount': next.total,
          if (next.isEmpty) 'lastUnlinkedAt': FieldValue.serverTimestamp() else 'lastUnlinkedAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      AppLogger.firestore('FoodImageService: link update failed', error: e);
    }
  }

  Future<FoodImage?> _findByUrl(String url) async {
    final col = _col;
    if (col == null || url.isEmpty) return null;
    try {
      final snap = await col.where('downloadUrl', isEqualTo: url).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return FoodImage.fromMap(snap.docs.first.data());
    } catch (e) {
      AppLogger.firestore('FoodImageService: lookup by URL failed', error: e);
      return null;
    }
  }

  @override
  Future<FoodImage?> getByHash(String hash) async {
    final col = _col;
    if (col == null || hash.isEmpty) return null;
    try {
      final snap = await col.doc(hash).get();
      if (!snap.exists) return null;
      return FoodImage.fromMap(snap.data()!);
    } catch (e) {
      AppLogger.firestore('FoodImageService: lookup by hash failed', error: e);
      return null;
    }
  }

  @override
  Future<String> resolveThumbUrl({required String fullUrl, String? hash}) async {
    final key = (hash != null && hash.isNotEmpty) ? hash : fullUrl;
    final mem = _thumbMem[key];
    if (mem != null) return mem;

    final uid = _uid;
    if (uid != null && hash != null && hash.isNotEmpty) {
      final cached = _readThumbCache()['$uid:$hash'];
      if (cached != null) {
        _thumbMem[key] = cached;
        return cached;
      }
    }

    FoodImage? image;
    if (hash != null && hash.isNotEmpty) {
      image = await getByHash(hash);
    }
    image ??= await _findByUrl(fullUrl);
    final thumb = image?.thumbUrl;
    if (thumb == null || thumb.isEmpty) return fullUrl;

    _thumbMem[key] = thumb;
    if (uid != null && hash != null && hash.isNotEmpty) {
      await _cacheThumb('$uid:$hash', thumb);
    }
    return thumb;
  }

  Map<String, String> _readThumbCache() {
    try {
      final raw = _prefs.getString(_thumbCacheKey);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _cacheThumb(String key, String thumbUrl) async {
    try {
      final cache = _readThumbCache()..[key] = thumbUrl;
      while (cache.length > _thumbCacheCap) {
        cache.remove(cache.keys.first);
      }
      await _prefs.setString(_thumbCacheKey, jsonEncode(cache));
    } catch (e) {
      AppLogger.firestore('FoodImageService: thumb cache write failed', error: e);
    }
  }
}
