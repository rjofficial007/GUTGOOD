import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class StorageService {
  /// Thumbnail profile (~320 px) for Storage uploads and history tiles.
  Future<Uint8List> compressImage(Uint8List bytes);

  /// Vision profile (~1280 px short edge) for anything sent to the AI proxy.
  Future<Uint8List> compressForAi(Uint8List bytes);
  Future<String?> uploadFoodImage(Uint8List bytes);
  Future<String?> uploadProfilePicture(Uint8List bytes);
}

class StorageServiceImpl implements StorageService {
  StorageServiceImpl({required FirebaseAuth auth, required FirebaseStorage storage, required SharedPreferences prefs, required FoodImageService foodImages})
    : _auth = auth,
      _storage = storage,
      _prefs = prefs,
      _foodImages = foodImages;
  final FirebaseAuth _auth;
  final FirebaseStorage _storage;
  final SharedPreferences _prefs;
  final FoodImageService _foodImages;

  /// hash → download URL for food images (audit §E dedup cache).
  static const _urlCacheKey = 'food_image_url_cache_v1';
  static const _urlCacheCap = 200;

  Map<String, String> _readUrlCache() {
    try {
      final raw = _prefs.getString(_urlCacheKey);
      if (raw == null || raw.isEmpty) return {};
      return (jsonDecode(raw) as Map).map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<void> _cacheUrl(String hash, String url) async {
    final cache = _readUrlCache()..[hash] = url;
    while (cache.length > _urlCacheCap) {
      cache.remove(cache.keys.first);
    }
    await _prefs.setString(_urlCacheKey, jsonEncode(cache));
  }

  String? get _uid => _auth.currentUser?.uid;

  @override
  Future<Uint8List> compressImage(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;
    try {
      final originalSize = bytes.lengthInBytes / 1024;
      AppLogger.info('StorageService: Original food image size: ${originalSize.toStringAsFixed(2)}KB');

      const maxBytes = 20 * 1024; // 20KB max
      var quality = 60;
      var compressedBytes = await FlutterImageCompress.compressWithList(
        bytes,
        minHeight: 320,
        minWidth: 320,
        quality: quality,
        format: CompressFormat.jpeg,
        autoCorrectionAngle: true,
        keepExif: false,
      );

      // Walk quality down until size <= 20KB or quality reaches minimum
      while (compressedBytes.lengthInBytes > maxBytes && quality > 15) {
        quality -= 10;
        compressedBytes = await FlutterImageCompress.compressWithList(
          bytes,
          minHeight: 320,
          minWidth: 320,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
      }

      final finalSize = compressedBytes.lengthInBytes / 1024;
      AppLogger.info('StorageService: Compressed food image size (target max 20KB): ${finalSize.toStringAsFixed(2)}KB');

      return compressedBytes;
    } catch (e, st) {
      AppLogger.error('StorageService: Compression failure', error: e, stackTrace: st);
      return bytes;
    }
  }

  // ---------------------------------------------------------------------------
  // AI vision profile
  // ---------------------------------------------------------------------------

  /// Short-edge target for images sent to the vision model.
  ///
  /// 320 px (the thumbnail profile above) is unreadable for the two features
  /// that depend on OCR-like reading — ingredient labels and restaurant menus.
  static const int _aiMinEdge = 1280;

  /// Quality ladder walked until the result fits [_aiTargetBytes].
  static const List<int> _aiQualityLadder = [78, 70, 60, 50];

  /// Comfortably under the proxy's MAX_IMAGE_BASE64_CHARS (1.6M chars ≈ 1.2 MB
  /// decoded). Images above that cap are rejected by the proxy.
  static const int _aiTargetBytes = 400 * 1024;

  @override
  Future<Uint8List> compressForAi(Uint8List bytes) async {
    if (bytes.isEmpty) return bytes;
    try {
      var best = bytes;
      for (final quality in _aiQualityLadder) {
        best = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: _aiMinEdge,
          minHeight: _aiMinEdge,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (best.lengthInBytes <= _aiTargetBytes) break;
      }

      AppLogger.info('StorageService: AI image ${(bytes.lengthInBytes / 1024).toStringAsFixed(0)}KB -> ${(best.lengthInBytes / 1024).toStringAsFixed(0)}KB');
      return best;
    } catch (e, st) {
      // Never block a scan on a compression failure — send the original bytes.
      AppLogger.error('StorageService: AI compression failure', error: e, stackTrace: st);
      return bytes;
    }
  }

  @override
  Future<String?> uploadFoodImage(Uint8List bytes) async {
    final uid = _uid;
    if (uid == null) {
      AppLogger.error('StorageService: Upload failed, user not authenticated');
      return null;
    }

    try {
      final compressedBytes = await compressImage(bytes);
      // Hash AFTER compression: the stored object is the compressed bytes,
      // so the same photo always lands on the same path — retries,
      // regenerates, and re-scans never re-upload (audit §E idempotent
      // hash path). Legacy timestamp-named objects keep working: stored
      // URLs are absolute, so only NEW uploads take hash paths.
      final hash = imageHash(compressedBytes);

      final cached = _readUrlCache()[hash];
      if (cached != null) {
        AppLogger.info('StorageService: dedup hit for food image $hash, upload skipped');
        return cached;
      }

      final storagePath = 'users/$uid/food_images/$hash.jpg';
      final ref = _storage.ref().child(storagePath);

      AppLogger.info('StorageService: Uploading to Firebase Storage: ${ref.fullPath}');

      final uploadTask = ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      AppLogger.info('StorageService: Food image upload successful: $url');
      await _cacheUrl(hash, url);
      // Best-effort registry record (links are added by the callers that
      // know the referencing docs). Never blocks the upload result.
      unawaited(_foodImages.registerImage(hash: hash, storagePath: storagePath, downloadUrl: url, bytes: compressedBytes.lengthInBytes));
      return url;
    } catch (e, st) {
      AppLogger.error('StorageService: uploadFoodImage exception', error: e, stackTrace: st);
      return null;
    }
  }

  @override
  Future<String?> uploadProfilePicture(Uint8List bytes) async {
    if (_uid == null) return null;

    try {
      final compressedBytes = await compressImage(bytes);
      const fileName = 'profile_pic.jpg';
      final ref = _storage.ref().child('users/$_uid/profile/$fileName');

      final uploadTask = ref.putData(compressedBytes, SettableMetadata(contentType: 'image/jpeg'));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      AppLogger.error('StorageService: Profile picture upload failed', error: e);
      return null;
    }
  }
}
