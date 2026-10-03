part of 'history_firestore_service.dart';

/// Firestore-backed history persistence implementation.

class HistoryFirestoreServiceImpl implements HistoryFirestoreService {
  HistoryFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db, required FoodImageService foodImages, GutScoreFirestoreService? gutScoreService}) : _auth = auth, _db = db, _foodImages = foodImages, _injectedGutScoreService = gutScoreService;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FoodImageService _foodImages;
  final GutScoreFirestoreService? _injectedGutScoreService;
  GutScoreFirestoreService? _legacyGutScoreService;

  // Keep the old constructor contract usable for compatibility callers while
  // allowing the composition root to inject the existing abstraction.
  GutScoreFirestoreService get _gutScoreService => _injectedGutScoreService ?? (_legacyGutScoreService ??= GutScoreFirestoreServiceImpl(auth: _auth, db: _db));

  String? get _uid => _auth.currentUser?.uid;
  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('user_profiles').doc(uid);
  }

  @override
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl, String? scanId}) async {
    try {
      final doc = _userDoc;
      final uid = _uid;
      if (doc == null || uid == null) return;

      final finalScanId = scanId ?? scanData.scanId ?? const Uuid().v4();

      // P2-6: no isSaved lookup on the save path. Saved state lives in the
      // `saved_foods` collection now; the per-doc flag below is just the
      // in-memory value (a legacy vestige that the lazy migration reads).

      var bestImageUrl = userImageUrl;
      if (bestImageUrl == null || bestImageUrl.isEmpty) {
        bestImageUrl = scanData.userImageUrl;
      }
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      AppLogger.firestore('Saving scan history for ${scanData.productName}. Image URL present: ${bestImageUrl != null}');

      // P0-2: persist via toPersistenceMap (rawData blob stripped, hash kept).
      final data = {...scanData.toPersistenceMap(), 'scanId': finalScanId, 'userId': uid, 'userImageUrl': bestImageUrl, 'createdAt': FieldValue.serverTimestamp()};

      await doc.collection('scan_history').doc(finalScanId).set(data, SetOptions(merge: true));
      AppLogger.firestore('Saved scan history doc: $finalScanId');
      // §E: link the user photo to this scan doc (no-op for OFF catalog
      // images and legacy timestamp uploads, which carry no hash).
      final hash = bestImageUrl == null ? null : imageHashFromFoodUrl(bestImageUrl);
      if (hash != null) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindScan, id: finalScanId);

      await _updateGutScoreRealTime();
    } catch (e) {
      AppLogger.firestore('Critical error saving to scan history', error: e);
    }
  }

  Future<void> _updateGutScoreRealTime() async {
    try {
      final uid = _uid;
      if (uid == null) return;

      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      final scans = await getRecentScans(since: thirtyDaysAgo);
      final meals = await getRecentMealLogs(since: thirtyDaysAgo);
      final symptoms = await getRecentSymptomLogs(since: thirtyDaysAgo);

      const calculator = GutScoreCalculatorService();
      final hasScore = calculator.hasScoreData(scans);
      final avgScanScore = calculator.calculateAvgScanScore(scans);
      final weeklyTrend = List<int>.from(calculator.calculateWeeklyTrend(scans: scans, symptoms: symptoms, meals: meals, endDate: now));
      final displayScore = hasScore ? avgScanScore : 0;

      final todayIndex = now.weekday % 7;
      if (todayIndex >= 0 && todayIndex < weeklyTrend.length) {
        weeklyTrend[todayIndex] = displayScore;
      }

      final startLocalDay = GutScoreCalculatorService.startOfLocalDay(now);
      final sunday = startLocalDay.subtract(Duration(days: startLocalDay.weekday % 7));
      final saturday = sunday.add(const Duration(days: 6));

      int isoWeekOf(DateTime date) {
        final local = date.toLocal();
        final dayOfYear = DateTime(local.year, local.month, local.day).difference(DateTime(local.year)).inDays + 1;
        return ((dayOfYear - local.weekday + 10) / 7).floor().clamp(1, 53);
      }

      final record = GutScoreRecord(
        id: 'weekly_${now.year}_W${isoWeekOf(now)}',
        uid: uid,
        type: 'weekly',
        scansCount: scans.length,
        mealsCount: meals.length,
        symptomsCount: symptoms.length,
        dailyScores: weeklyTrend,
        periodFrom: sunday.toUtc(),
        periodTo: saturday.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)).toUtc(),
        createdAt: now.toUtc(),
      );

      await _gutScoreService.saveGutScore(record);
      AppLogger.firestore('HistoryFirestoreService: Real-time gut score updated ($displayScore) for both collections.');
    } catch (e) {
      AppLogger.firestore('Error updating real-time gut score', error: e);
    }
  }

  @override
  Future<ScanResult?> getScanById(String scanId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;

      final snap = await doc.collection('scan_history').doc(scanId).get();
      if (!snap.exists) return null;

      return ScanResult.fromMap({...snap.data()!, 'id': snap.id});
    } catch (e) {
      AppLogger.firestore('Error getting scan by ID: $scanId', error: e);
      return null;
    }
  }

  @override
  Future<ScanResult?> getLatestScanByBarcode(String barcode) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;

      final snap = await doc.collection('scan_history').where('barcode', isEqualTo: barcode).orderBy('createdAt', descending: true).limit(1).get();
      if (snap.docs.isEmpty) return null;
      return ScanResult.fromMap({...snap.docs.first.data(), 'id': snap.docs.first.id});
    } catch (e) {
      AppLogger.firestore('Error getting latest scan for barcode', error: e);
      return null;
    }
  }

  @override
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Robust Query: Fetch all scans and filter in-memory to support legacy data (where 'source' might be missing)
      // and ensure consistent behavior with ScanResult.isLoggableProduct.
      var query = doc.collection('scan_history').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      // If we have a limit, we fetch a bit more to account for filtered items,
      // though for most users the filter won't remove many items.
      if (limit != null) {
        query = query.limit(limit * 2);
      }

      final snapshot = await query.get();

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final scan = ScanResult.fromMap({...data, 'id': doc.id});

          // Only show legitimate products in the main Scan History (filters out menus/labels)
          if (scan.isLoggableProduct) {
            results.add(scan);
          }

          if (limit != null && results.length >= limit) break;
        } catch (e) {
          AppLogger.error('Failed to parse scan history document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting scan history', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getLabelScans({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query scan_history with source='label'
      var query = doc.collection('scan_history').where('source', isEqualTo: 'label').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          results.add(
            ScanResult.fromMap({
              ...data,
              'id': doc.id,
              'brand': data['brandName'] ?? data['brand'] ?? 'Unknown',
              'userImageUrl': data['userImageUrl'] ?? data['scanImage'],
              'category': 'label',
              'source': 'label',
            }),
          );
        } catch (e) {
          AppLogger.error('Failed to parse label scan document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting label scans', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getMenuScans({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query scan_history with source='menu'
      var query = doc.collection('scan_history').where('source', isEqualTo: 'menu').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // For menus, productName is restaurantName
          final restaurantName = data['restaurantName'] ?? 'Unknown Restaurant';
          results.add(ScanResult.fromMap({...data, 'id': doc.id, 'productName': restaurantName, 'userImageUrl': data['userImageUrl'] ?? data['menuImage'], 'category': 'menu', 'source': 'menu'}));
        } catch (e) {
          AppLogger.error('Failed to parse menu scan document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting menu scans', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getRecentScans({int? limit, DateTime? since, DateTime? before}) async => getScanHistory(limit: limit, since: since, before: before);

  @override
  Future<void> toggleSaveFood(ScanResult scanData) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      // P2-6: one doc per product in `saved_foods` — no more batch-updating
      // every history instance. The full scan map is embedded so saved items
      // render offline and survive scan_history deletion (chat-delete cascade).
      final key = savedFoodKey(barcode: scanData.barcode, productName: scanData.productName);
      final ref = doc.collection('saved_foods').doc(key);
      final isCurrentlySaved = await isFoodSaved(scanData.productName, barcode: scanData.barcode);

      if (isCurrentlySaved) {
        await ref.delete();
        // Required for correctness: a stale legacy flag would resurrect the
        // item via the isFoodSaved fallback below.
        await _clearLegacySavedFlags(doc, scanData);
      } else {
        await ref.set({...scanData.toPersistenceMap(), 'scanRef': scanData.scanId, 'savedAt': FieldValue.serverTimestamp(), 'isSaved': true});
      }

      AppLogger.firestore('Toggled saved_foods/$key to ${!isCurrentlySaved} for ${scanData.productName}');
    } catch (e) {
      AppLogger.firestore('Error toggling saved food', error: e);
    }
  }

  /// One-way legacy cleanup: clears pre-P2-6 `isSaved` flags for a product.
  /// Runs only on unsave, so the old batch behavior can't recur on save.
  Future<void> _clearLegacySavedFlags(DocumentReference doc, ScanResult scanData) async {
    try {
      final collection = doc.collection('scan_history');
      final Query query = (scanData.barcode != null && scanData.barcode!.isNotEmpty)
          ? collection.where('barcode', isEqualTo: scanData.barcode)
          : collection.where('productName', isEqualTo: scanData.productName);
      final snapshot = await query.where('isSaved', isEqualTo: true).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _db.batch();
      for (final d in snapshot.docs) {
        batch.update(d.reference, {'isSaved': false});
      }
      await batch.commit();
    } catch (e) {
      AppLogger.firestore('Error clearing legacy saved flags', error: e);
    }
  }

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return false;

      // P2-6: single doc get. The legacy flag query below only runs when no
      // saved_foods doc exists (pre-migration users), and the migration in
      // getSavedFoods steadily empties that fallback.
      final ref = doc.collection('saved_foods').doc(savedFoodKey(barcode: barcode, productName: productName ?? ''));
      if ((await ref.get()).exists) return true;

      final collection = doc.collection('scan_history');
      final Query query = (barcode != null && barcode.isNotEmpty) ? collection.where('barcode', isEqualTo: barcode) : collection.where('productName', isEqualTo: productName);

      final snapshot = await query.where('isSaved', isEqualTo: true).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ScanResult>> getSavedFoods() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // P2-6: the collection IS the deduped list (one doc per product).
      // Small N, so ordering happens client-side — no composite index needed.
      final snapshot = await doc.collection('saved_foods').get();
      final items = <String, ScanResult>{};
      for (final d in snapshot.docs) {
        final scan = ScanResult.fromMap({...d.data(), 'id': d.id});
        items[savedFoodKey(barcode: scan.barcode, productName: scan.productName)] = scan;
      }

      // Lazy migration: union pre-P2-6 flagged scans, backfill them into
      // saved_foods, and clear their flags so this query empties over time.
      final legacy = await doc.collection('scan_history').where('isSaved', isEqualTo: true).get();
      if (legacy.docs.isNotEmpty) {
        final batch = _db.batch();
        for (final d in legacy.docs) {
          final scan = ScanResult.fromMap({...d.data(), 'id': d.id});
          final key = savedFoodKey(barcode: scan.barcode, productName: scan.productName);
          // Backfill only when no doc exists: a newer toggle-save must never
          // be overwritten by stale legacy data. The flag clears regardless.
          if (!items.containsKey(key)) {
            items[key] = scan;
            batch.set(doc.collection('saved_foods').doc(key), {...d.data(), 'scanRef': scan.scanId, 'savedAt': d.data()['createdAt'], 'isSaved': true});
          }
          batch.update(d.reference, {'isSaved': false});
        }
        await batch.commit();
      }

      final list = items.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      AppLogger.firestore('Error getting saved foods', error: e);
      return [];
    }
  }

  @override
  Future<String?> logMeal(MealLog log, {String? docId}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      // 🚀 PRD §13 & §14: Support deterministic IDs for idempotency.
      final docRef = doc.collection('journal_logs').doc(docId);
      final data = {
        ...log.toMap(),
        'firestoreId': docRef.id,
        'type': 'meal',
        'source': log.source ?? 'chat',
        'createdAt': log.createdAt, // Log time (ordering clock); AI estimates live in occurredAt
        'loggedAt': FieldValue.serverTimestamp(),
      };
      await docRef.set(data, SetOptions(merge: true));
      // §E: link the meal photo (the turn's image, via photoUrl).
      final hash = log.photoUrl == null ? null : imageHashFromFoodUrl(log.photoUrl!);
      if (hash != null) await _foodImages.addLink(hash: hash, kind: FoodImageLinks.kindMeal, id: docRef.id);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging meal to journal_logs', error: e);
      return null;
    }
  }

  @override
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query journal_logs with type='meal'
      var query = doc.collection('journal_logs').where('type', isEqualTo: 'meal').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => MealLog.fromMap(doc.data())).toList();
      return results;
    } catch (e) {
      AppLogger.firestore('Error getting recent meal logs', error: e);
      return [];
    }
  }

  @override
  Future<String?> logSymptom(SymptomLog log, {String? docId}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      // 🚀 PRD §13 & §14: Support deterministic IDs for idempotency.
      final docRef = doc.collection('journal_logs').doc(docId);
      final data = {...log.toMap(), 'firestoreId': docRef.id, 'type': 'symptom', 'source': log.source ?? 'manual', 'createdAt': log.createdAt, 'loggedAt': FieldValue.serverTimestamp()};
      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging symptom to journal_logs', error: e);
      return null;
    }
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query journal_logs with type='symptom'
      var query = doc.collection('journal_logs').where('type', isEqualTo: 'symptom').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
      return results;
    } catch (e) {
      AppLogger.firestore('Error getting recent symptom logs', error: e);
      return [];
    }
  }

  /// Runs a server-side `count()` aggregation instead of downloading documents.
  /// Bills ~1 read per 1000 index entries (vs 1 read per document) and never
  /// throws — failures (e.g. offline) resolve to 0.
  Future<int> _countQuery(Query<Map<String, dynamic>> query, String label, {int onError = 0}) async {
    try {
      final snapshot = await query.count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      AppLogger.firestore('Count query failed ($label)', error: e);
      return onError;
    }
  }

  @override
  Future<int> getMealLogsCountSince(DateTime since) async {
    final doc = _userDoc;
    // No user resolved yet → "unknown", not "no meals".
    if (doc == null) return -1;
    return _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'meal').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)), 'meals-since', onError: -1);
  }

  @override
  Future<int> getSymptomLogsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return -1;
    return _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'symptom').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)), 'symptoms-since', onError: -1);
  }

  @override
  Future<int> getScansCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return -1;
    return _countQuery(doc.collection('scan_history').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)), 'scans-since', onError: -1);
  }

  @override
  Stream<HistoryCounts> watchHistoryCounts() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(HistoryCounts.zero);
    final countersRef = doc.collection('counters').doc('totals');
    return countersRef
        .snapshots()
        .asyncMap((snap) async {
          try {
            final data = snap.data();
            if (snap.exists && data != null) return HistoryCounts.fromMap(data);
            // Transitional fallback: the counters doc is seeded lazily by the
            // first trigger run. Until then, answer with cheap count()
            // aggregations so existing users never see zeroed stats or have
            // insight generation wrongly gated off.
            final results = await Future.wait([
              _countQuery(doc.collection('scan_history'), 'scans-total'),
              _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'meal'), 'meals-total'),
              _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'symptom'), 'symptoms-total'),
            ]);
            return HistoryCounts(scans: results[0], meals: results[1], symptoms: results[2]);
          } catch (e) {
            AppLogger.firestore('Error watching history counts', error: e);
            return HistoryCounts.zero;
          }
        })
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('History counts permission denied (signed out?)');
          } else {
            throw e;
          }
        });
  }

  @override
  Stream<int> getAverageFoodScoreStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);

    return doc.collection('counters').doc('totals').snapshots().asyncMap((snap) async {
      try {
        final data = snap.data();
        if (snap.exists && data != null) return HistoryCounts.fromMap(data).averageFoodScore;
        return await _legacyAverageFoodScore();
      } catch (e) {
        AppLogger.firestore('Error watching average food score', error: e);
        return 0;
      }
    });
  }

  /// Pre-counters full-read average. Only runs while `counters/totals` is
  /// missing (accounts created before the counters rollout, before their next
  /// logged scan or meal). Never called once counters exist.
  Future<int> _legacyAverageFoodScore() async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('scan_history').get();
    return _calculateAverage(snapshot.docs);
  }

  int _calculateAverage(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return 0;

    final scores = docs.map((doc) => ScanResult.fromMap(doc.data())).where((s) => s.isLoggableProduct).map((s) => s.score).toList();

    if (scores.isEmpty) return 0;

    final sum = scores.reduce((a, b) => a + b);
    return (sum / scores.length).round();
  }

  @override
  Future<void> deleteLogsForMessage(String chatMessageId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      final batch = _db.batch();

      // Find and delete associated logs from journal_logs. §E: unlink meal
      // photos BEFORE the batch deletes the docs that name them.
      final journalSnaps = await doc.collection('journal_logs').where('chatMessageId', isEqualTo: chatMessageId).get();
      for (final d in journalSnaps.docs) {
        final photoUrl = d.data()['photoUrl'] as String?;
        final hash = photoUrl == null ? null : imageHashFromFoodUrl(photoUrl);
        if (hash != null) await _foodImages.removeLink(hash: hash, kind: FoodImageLinks.kindMeal, id: d.id);
        batch.delete(d.reference);
      }

      // 🚀 Also delete the associated scan analysis if it was linked to this message
      for (final scanId in [chatMessageId, '${chatMessageId}_scan']) {
        final scanDoc = await doc.collection('scan_history').doc(scanId).get();
        final userImageUrl = scanDoc.data()?['userImageUrl'] as String?;
        final hash = userImageUrl == null ? null : imageHashFromFoodUrl(userImageUrl);
        if (hash != null) await _foodImages.removeLink(hash: hash, kind: FoodImageLinks.kindScan, id: scanId);
        batch.delete(doc.collection('scan_history').doc(scanId));
      }

      await batch.commit();
      AppLogger.firestore('Deleted journal logs associated with chatMessageId: $chatMessageId');
    } catch (e) {
      AppLogger.firestore('Error deleting journal logs for message', error: e);
    }
  }
}
