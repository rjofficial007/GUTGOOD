import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class SwapRecommendationFirestoreService {
  Future<List<SwapAlternative>?> getCachedSwaps({
    required String sourceFoodName,
    required Map<String, Object?> requestContext,
    required int promptVersion,
  });

  Future<void> saveSwaps({
    required String sourceFoodName,
    required Map<String, Object?> requestContext,
    required int promptVersion,
    required List<SwapAlternative> alternatives,
  });
}

class SwapRecommendationFirestoreServiceImpl
    implements SwapRecommendationFirestoreService {
  SwapRecommendationFirestoreServiceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
  }) : _auth = auth,
       _db = db;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>>? get _collection {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return null;
    }
    return _db
        .collection('user_profiles')
        .doc(uid)
        .collection('swap_recommendations');
  }

  String _sourceKey(String sourceFoodName) => sha256
      .convert(utf8.encode(_normalize(sourceFoodName)))
      .toString()
      .substring(0, 32);

  String _contextHash(Map<String, Object?> requestContext, int promptVersion) =>
      sha256
          .convert(
            utf8.encode(
              '$promptVersion|${jsonEncode(_canonicalize(requestContext))}',
            ),
          )
          .toString();

  @override
  Future<List<SwapAlternative>?> getCachedSwaps({
    required String sourceFoodName,
    required Map<String, Object?> requestContext,
    required int promptVersion,
  }) async {
    final source = _normalize(sourceFoodName);
    final collection = _collection;
    if (collection == null || source.isEmpty) {
      return null;
    }
    try {
      final snapshot = await collection.doc(_sourceKey(source)).get();
      final data = snapshot.data();
      if (!snapshot.exists ||
          data == null ||
          data['contextHash'] != _contextHash(requestContext, promptVersion)) {
        return null;
      }
      final rawAlternatives = data['alternatives'];
      if (rawAlternatives is! List) {
        return null;
      }

      final seen = <String>{};
      final alternatives = <SwapAlternative>[];
      for (final raw in rawAlternatives.whereType<Map>()) {
        final alternative = SwapAlternative.fromMap(
          Map<String, dynamic>.from(raw),
        );
        final name = _normalize(alternative.name);
        if (name.isEmpty ||
            name == source ||
            alternative.reason?.trim().isNotEmpty != true ||
            !seen.add(name)) {
          continue;
        }
        alternatives.add(alternative);
        if (alternatives.length == 4) {
          break;
        }
      }
      return alternatives.isEmpty ? null : alternatives;
    } catch (error) {
      AppLogger.firestore(
        'Swap recommendation cache read failed',
        error: error,
      );
      return null;
    }
  }

  @override
  Future<void> saveSwaps({
    required String sourceFoodName,
    required Map<String, Object?> requestContext,
    required int promptVersion,
    required List<SwapAlternative> alternatives,
  }) async {
    final source = sourceFoodName.trim();
    final collection = _collection;
    if (collection == null ||
        _normalize(source).isEmpty ||
        alternatives.isEmpty) {
      return;
    }
    try {
      await collection.doc(_sourceKey(source)).set({
        'sourceFoodName': source,
        'contextHash': _contextHash(requestContext, promptVersion),
        'promptVersion': promptVersion,
        'alternatives': alternatives
            .take(4)
            .map((alternative) => alternative.toMap())
            .toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Recommendations stay usable if this optional cache write fails.
      AppLogger.firestore(
        'Swap recommendation cache write failed',
        error: error,
      );
    }
  }

  Object? _canonicalize(Object? value) {
    if (value is Map) {
      final keys = value.keys.map((key) => key.toString()).toList()..sort();
      return {for (final key in keys) key: _canonicalize(value[key])};
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList();
    }
    return value;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
