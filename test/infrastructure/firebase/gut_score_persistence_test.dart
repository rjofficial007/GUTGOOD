// The sealed Firestore SDK types are mocked only to exercise persistence failures.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockDb extends Mock implements FirebaseFirestore {}

class MockCollection extends Mock implements CollectionReference<Map<String, dynamic>> {}

class MockDoc extends Mock implements DocumentReference<Map<String, dynamic>> {}

class MockSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}

class MockQueryDoc extends Mock implements QueryDocumentSnapshot<Map<String, dynamic>> {}

class MockTransaction extends Mock implements Transaction {}

class MockBatch extends Mock implements WriteBatch {}

class MockFoodImages extends Mock implements FoodImageService {}

class MockScores extends Mock implements GutScoreFirestoreService {}

void main() {
  late MockAuth auth;
  late MockDb db;
  late MockDoc profileRef;
  late MockCollection scans;
  late MockCollection journal;
  late MockDoc scanRef;
  late MockDoc journalRef;
  late MockQuerySnapshot scanSnapshot;
  late MockQuerySnapshot journalSnapshot;
  late MockScores scores;
  late HistoryFirestoreService history;
  late List<QueryDocumentSnapshot<Map<String, dynamic>>> scanDocs;
  late List<QueryDocumentSnapshot<Map<String, dynamic>>> journalDocs;

  QueryDocumentSnapshot<Map<String, dynamic>> stored(String id, Map<String, dynamic> data) {
    final doc = MockQueryDoc();
    when(() => doc.id).thenReturn(id);
    when(doc.data).thenReturn(data);
    return doc;
  }

  setUpAll(() {
    registerFallbackValue(MockDoc());
    registerFallbackValue(SetOptions(merge: true));
    registerFallbackValue((Transaction _) async {});
    registerFallbackValue(const GutScoreCalculatorService().calculateWeeklyRecord(uid: 'user', scans: const [], symptoms: const [], meals: const [], asOf: DateTime(2026)));
  });

  setUp(() {
    auth = MockAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('user');
    when(() => auth.currentUser).thenReturn(user);
    db = MockDb();
    profileRef = MockDoc();
    final profiles = MockCollection();
    when(() => db.collection('user_profiles')).thenReturn(profiles);
    when(() => profiles.doc('user')).thenReturn(profileRef);
    scans = MockCollection();
    journal = MockCollection();
    when(() => profileRef.collection('scan_history')).thenReturn(scans);
    when(() => profileRef.collection('journal_logs')).thenReturn(journal);
    scanRef = MockDoc();
    journalRef = MockDoc();
    when(() => scanRef.id).thenReturn('msg_scan');
    when(() => journalRef.id).thenReturn('entry');
    when(() => scans.doc(any())).thenReturn(scanRef);
    when(() => journal.doc(any())).thenReturn(journalRef);
    scanDocs = [];
    journalDocs = [];
    scanSnapshot = MockQuerySnapshot();
    journalSnapshot = MockQuerySnapshot();
    when(() => scanSnapshot.docs).thenAnswer((_) => scanDocs);
    when(() => journalSnapshot.docs).thenAnswer((_) => journalDocs);
    final scanQuery = MockQuery();
    final journalQuery = MockQuery();
    when(() => scans.where('createdAt', isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'))).thenReturn(scanQuery);
    when(() => journal.where('createdAt', isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'))).thenReturn(journalQuery);
    when(scanQuery.get).thenAnswer((_) async => scanSnapshot);
    when(journalQuery.get).thenAnswer((_) async => journalSnapshot);
    when(() => scanRef.set(any(), any())).thenAnswer((invocation) async {
      scanDocs = [stored('msg_scan', invocation.positionalArguments[0] as Map<String, dynamic>)];
    });
    when(() => journalRef.set(any(), any())).thenAnswer((invocation) async {
      journalDocs.add(stored('entry', invocation.positionalArguments[0] as Map<String, dynamic>));
    });
    scores = MockScores();
    when(() => scores.saveGutScore(any())).thenAnswer((_) async {});
    history = HistoryFirestoreServiceImpl(auth: auth, db: db, foodImages: MockFoodImages(), gutScoreService: scores);
  });

  test('scan, meal, symptom and deletion writes all refresh the same score', () async {
    final now = DateTime.now();
    final scan = ScanResult(productName: 'Oats', brand: 'Brand', consumed: true, category: 'food', score: 80, impactType: ImpactType.positive, impact: '', createdAt: now);
    expect(await history.trySaveToScanHistory(scan, scanId: 'msg_scan'), isTrue);
    expect(
      await history.logMeal(
        MealLog(items: const ['Oats'], createdAt: now),
        docId: 'meal',
      ),
      'entry',
    );
    expect(
      await history.logSymptom(
        SymptomLog(symptom: 'Bloating', severity: 10, createdAt: now, journalEntryId: 'meal'),
        docId: 'symptom',
      ),
      'entry',
    );

    final deletedQuery = MockQuery();
    when(() => journal.where('chatMessageId', isEqualTo: 'msg')).thenReturn(deletedQuery);
    when(deletedQuery.get).thenAnswer((_) async => journalSnapshot);
    final emptyScan = MockSnapshot();
    when(emptyScan.data).thenReturn(null);
    when(scanRef.get).thenAnswer((_) async => emptyScan);
    final batch = MockBatch();
    when(() => db.batch()).thenReturn(batch);
    when(() => batch.delete(any())).thenAnswer((_) {});
    when(batch.commit).thenAnswer((_) async {
      scanDocs = [];
      journalDocs = [];
    });
    for (final doc in journalDocs) {
      when(() => doc.reference).thenReturn(journalRef);
    }
    await history.deleteLogsForMessage('msg');

    final records = verify(() => scores.saveGutScore(captureAny())).captured.cast<GutScoreRecord>();
    expect(records.map((record) => record.gutScore), [82, 82, 73, 0]);
    expect(records.last.hasScore, isFalse);
    expect(records.last.scansCount, 0);
    expect(records.map((record) => record.id).toSet(), hasLength(1));
  });

  test('failed input read keeps the previous score and the saved meal', () async {
    final failedQuery = MockQuery();
    when(() => scans.where('createdAt', isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'))).thenReturn(failedQuery);
    when(failedQuery.get).thenThrow(StateError('offline'));

    expect(
      await history.logMeal(
        MealLog(items: const ['Oats'], createdAt: DateTime.now()),
        docId: 'meal',
      ),
      'entry',
    );
    verifyNever(() => scores.saveGutScore(any()));
    expect(journalDocs, hasLength(1));

    when(failedQuery.get).thenAnswer((_) async => scanSnapshot);
    await history.refreshGutScore();
    verify(() => scores.saveGutScore(any())).called(1);
  });

  test('queued refreshes publish in order and include the newest scan', () async {
    final now = DateTime.now();
    Map<String, dynamic> scan(int score) => ScanResult(productName: 'Oats', brand: 'Brand', consumed: true, score: score, impactType: ImpactType.positive, impact: '', createdAt: now).toMap();
    scanDocs = [stored('scan', scan(80))];
    final firstSaveStarted = Completer<void>();
    final releaseFirstSave = Completer<void>();
    final published = <int>[];
    when(() => scores.saveGutScore(any())).thenAnswer((invocation) async {
      published.add((invocation.positionalArguments.single as GutScoreRecord).gutScore);
      if (published.length == 1) {
        firstSaveStarted.complete();
        await releaseFirstSave.future;
      }
    });
    final first = history.refreshGutScore();
    await firstSaveStarted.future;
    scanDocs = [stored('scan', scan(90))];
    final second = history.refreshGutScore();
    expect(published, [82]);
    releaseFirstSave.complete();
    await Future.wait([first, second]);
    expect(published, [82, 92]);
  });

  test('an account change during input reads cannot publish the previous user’s score', () async {
    final other = MockUser();
    when(() => other.uid).thenReturn('other');
    final query = MockQuery();
    when(() => scans.where('createdAt', isGreaterThanOrEqualTo: any(named: 'isGreaterThanOrEqualTo'))).thenReturn(query);
    when(query.get).thenAnswer((_) async {
      when(() => auth.currentUser).thenReturn(other);
      return scanSnapshot;
    });
    await history.refreshGutScore();
    verifyNever(() => scores.saveGutScore(any()));
  });

  test('rule-based insight and pattern evidence are committed in one batch', () async {
    final insights = MockCollection();
    final patterns = MockCollection();
    final insightRef = MockDoc();
    final patternRef = MockDoc();
    final batch = MockBatch();
    when(() => profileRef.collection('insights')).thenReturn(insights);
    when(() => profileRef.collection('pattern_data')).thenReturn(patterns);
    when(() => insights.doc('rule_based_latest')).thenReturn(insightRef);
    when(() => patterns.doc('latest')).thenReturn(patternRef);
    when(() => insightRef.id).thenReturn('rule_based_latest');
    when(() => db.batch()).thenReturn(batch);
    when(() => batch.set<Map<String, dynamic>>(any(), any())).thenAnswer((_) {});
    when(batch.commit).thenAnswer((_) async {});
    final snapshot = AIInsight(
      uid: 'user',
      firestoreId: 'rule_based_latest',
      origin: AIInsight.originRuleBased,
      gutScore: 0,
      hasGutScore: false,
      updatedAt: DateTime.now(),
      detectedPatterns: const [],
    );
    final service = InsightFirestoreServiceImpl(auth: auth, db: db);

    expect(await service.saveInsights(snapshot), 'rule_based_latest');
    verify(() => batch.set<Map<String, dynamic>>(insightRef, any())).called(1);
    final evidence = verify(() => batch.set<Map<String, dynamic>>(patternRef, captureAny())).captured.single as Map<String, dynamic>;
    expect(evidence['patterns'], isEmpty);
    verify(batch.commit).called(1);
    verifyNever(() => insightRef.set(any()));
  });

  test('complete analysis pages past 150 records with a document cursor', () async {
    final first = MockQuery();
    final second = MockQuery();
    final firstSnapshot = MockQuerySnapshot();
    final secondSnapshot = MockQuerySnapshot();
    final now = DateTime.now();
    final docs = List.generate(
      150,
      (index) => stored('meal-$index', {
        'type': 'meal',
        'items': ['Oats'],
        'createdAt': now,
      }),
    );
    when(() => journal.where('type', isEqualTo: 'meal')).thenReturn(first);
    when(() => first.orderBy('createdAt', descending: true)).thenReturn(first);
    when(() => first.limit(150)).thenReturn(first);
    when(() => first.startAfterDocument(docs.last)).thenReturn(second);
    when(() => second.limit(150)).thenReturn(second);
    when(() => firstSnapshot.docs).thenReturn(docs);
    final lastDoc = stored('meal-150', {
      'type': 'meal',
      'items': ['Rice'],
      'createdAt': now,
    });
    when(() => secondSnapshot.docs).thenReturn([lastDoc]);
    when(() => first.get(const GetOptions(source: Source.server))).thenAnswer((_) async => firstSnapshot);
    when(() => second.get(const GetOptions(source: Source.server))).thenAnswer((_) async => secondSnapshot);

    final meals = await history.getRecentMealLogs(throwOnError: true);
    expect(meals, hasLength(151));
    expect(meals.last.firestoreId, 'meal-150');
  });

  group('atomic score persistence', () {
    late GutScoreFirestoreService service;
    late MockTransaction transaction;
    late MockSnapshot profileSnapshot;
    late MockDoc scoreRef;
    late MockCollection scoreCollection;
    late GutScoreRecord record;

    setUp(() {
      service = GutScoreFirestoreServiceImpl(auth: auth, db: db);
      transaction = MockTransaction();
      profileSnapshot = MockSnapshot();
      scoreRef = MockDoc();
      scoreCollection = MockCollection();
      when(() => profileRef.collection('gut_scores')).thenReturn(scoreCollection);
      when(() => scoreCollection.doc(any())).thenReturn(scoreRef);
      when(() => profileSnapshot.data()).thenReturn({});
      when(() => transaction.get(profileRef)).thenAnswer((_) async => profileSnapshot);
      when(() => transaction.set<Map<String, dynamic>>(scoreRef, any())).thenReturn(transaction);
      when(() => transaction.set<Map<String, dynamic>>(profileRef, any(), any())).thenReturn(transaction);
      when(() => db.runTransaction<void>(any())).thenAnswer((invocation) async {
        await (invocation.positionalArguments.first as TransactionHandler<void>)(transaction);
      });
      final now = DateTime.now();
      record = const GutScoreCalculatorService().calculateWeeklyRecord(
        uid: 'user',
        scans: [ScanResult(productName: 'Oats', brand: 'Brand', consumed: true, score: 80, impactType: ImpactType.positive, impact: '', createdAt: now)],
        symptoms: const [],
        meals: const [],
        asOf: now,
      );
    });

    test('record and profile mirror are committed in one transaction', () async {
      await service.saveGutScore(record);
      verify(() => scoreCollection.doc(record.id)).called(1);
      final saved = verify(() => transaction.set<Map<String, dynamic>>(scoreRef, captureAny())).captured.single as Map<String, dynamic>;
      final mirror = verify(() => transaction.set<Map<String, dynamic>>(profileRef, captureAny(), any())).captured.single as Map<String, dynamic>;
      expect(saved['gutScore'], 82);
      expect(mirror['gutScore'], saved['gutScore']);
      expect(mirror['hasGutScore'], isTrue);
    });

    test('an older calculation cannot overwrite a newer score', () async {
      when(() => profileSnapshot.data()).thenReturn({'lastScoreCalculationAt': Timestamp.fromDate(record.createdAt.add(const Duration(seconds: 1)))});
      await service.saveGutScore(record);
      verifyNever(() => transaction.set<Map<String, dynamic>>(scoreRef, any()));
      verifyNever(() => transaction.set<Map<String, dynamic>>(profileRef, any(), any()));
    });

    test('account mismatch is rejected before writing', () async {
      final other = MockUser();
      when(() => other.uid).thenReturn('other');
      when(() => auth.currentUser).thenReturn(other);
      final profiles = MockCollection();
      when(() => db.collection('user_profiles')).thenReturn(profiles);
      when(() => profiles.doc('other')).thenReturn(profileRef);
      await expectLater(service.saveGutScore(record), throwsStateError);
      verifyNever(() => db.runTransaction<void>(any()));
    });

    test('transaction failures are reported to the refresh caller', () async {
      when(() => db.runTransaction<void>(any())).thenThrow(StateError('permission denied'));
      await expectLater(service.saveGutScore(record), throwsStateError);
    });
  });
}
