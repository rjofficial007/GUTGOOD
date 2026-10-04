import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/features/scanner/data/repositories/scanner_repository_impl.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:mocktail/mocktail.dart';

class MockOffService extends Mock implements OffService {}

class MockAiService extends Mock implements AiClient {}

class MockAiClassifierService extends Mock implements AiClassifierService {}

class MockProcessChatTagUseCase extends Mock implements ProcessChatTagUseCase {}

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockNotificationService extends Mock implements NotificationService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockStreakService extends Mock implements StreakService {}

/// A realistic persisted barcode scan: label facts present, model score
/// deliberately bogus (1) so a pass-through bug can't hide behind it.
ScanResult _cachedScan({DateTime? createdAt}) => ScanResult(
  productName: 'Cache Yogurt',
  brand: 'Cache Brand',
  category: 'food',
  barcode: '111222333',
  score: 1,
  impactType: ImpactType.neutral,
  impact: 'Cached impact',
  nutriscore: 'B',
  nutriscoreScore: 0,
  isOrganic: false,
  nutrients: const NutrientData(calories: 80, saturatedFat: 1.2, sugars: 9, fiber: 0.5, proteins: 4.5, salt: 0.1),
  additiveItems: const ['E330'],
  ingredients: const [Ingredient(name: 'Milk powder', impact: '', colorName: 'low')],
  flaggedIngredients: const ['Whey'],
  createdAt: createdAt ?? DateTime.now(),
);

void main() {
  late MockHistoryFirestoreService history;
  late MockChatFirestoreService chat;
  late MockAnalyticsService analytics;
  late ScannerRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()));
    registerFallbackValue(ScanResult(productName: '', brand: '', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()));
    registerFallbackValue(MealLog(items: const [], createdAt: DateTime.now()));
    registerFallbackValue(SymptomLog(symptom: '', createdAt: DateTime.now()));
  });

  setUp(() {
    history = MockHistoryFirestoreService();
    chat = MockChatFirestoreService();
    analytics = MockAnalyticsService();
    repo = ScannerRepositoryImpl(
      offService: MockOffService(),
      aiService: MockAiService(),
      aiClassifierService: MockAiClassifierService(),
      chatFirestoreService: chat,
      historyFirestoreService: history,
      notificationService: MockNotificationService(),
      appStateService: MockAppStateService(),
      analyticsService: analytics,
      streakService: MockStreakService(),
      processChatTagUseCase: MockProcessChatTagUseCase(),
      eventPersister: DomainEventPersister(historyFirestoreService: history),
    );

    when(() => chat.saveMessage(any())).thenAnswer((_) async => 'msg-id');
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    when(() => history.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'cached-meal-id');
    when(
      () => history.trySaveToScanHistory(
        any(),
        userImageUrl: any(named: 'userImageUrl'),
        scanId: any(named: 'scanId'),
      ),
    ).thenAnswer((_) async => true);
  });

  group('getCachedBarcodeScan (P0-3)', () {
    test('miss (never scanned) returns null and records nothing', () async {
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => null);

      final result = await repo.getCachedBarcodeScan(barcode: '000', sensitivities: const ['Dairy']);

      expect(result, isNull);
      verifyNever(() => chat.saveMessage(any()));
      verifyNever(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      );
    });

    test('stale entry (older than 30 days) falls through to full analysis', () async {
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => _cachedScan(createdAt: DateTime.now().subtract(const Duration(days: 31))));

      final result = await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const []);

      expect(result, isNull);
      verifyNever(() => chat.saveMessage(any()));
    });

    test('fresh hit re-runs the engine exactly (never passes the stored score through)', () async {
      final cached = _cachedScan();
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => cached);

      final result = await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const []);

      expect(result, isNotNull);
      final expected = YukaScore.evaluate(
        nutriscore: cached.nutriscore,
        nutriscoreScore: cached.nutriscoreScore,
        energyKcal: cached.nutrients?.calories,
        fiberG: cached.nutrients?.fiber,
        proteinG: cached.nutrients?.proteins,
        sugarG: cached.nutrients?.sugars,
        saltG: cached.nutrients?.salt,
        saturatedFatG: cached.nutrients?.saturatedFat,
        additiveConcerns: AdditiveConcernDb.resolveAll(cached.additiveItems),
        isOrganic: cached.isOrganic,
      );
      expect(result!.score, expected.score);
      expect(result.score, isNot(1), reason: 'The bogus stored score must be replaced by the engine result.');
      expect(result.impact, expected.explanation, reason: 'The engine recomposes the explanation fresh.');
    });

    test('fresh hit creates a new scan event and consumed meal projection', () async {
      final cached = _cachedScan().copyWith(scanId: 'original-scan', chatMessageId: 'original-turn');
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => cached);

      final result = await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const []);

      expect(result, isNotNull);
      final cachedResult = result!;
      final scanId = cachedResult.scanId!;
      expect(scanId, isNot('original-scan'));
      expect(scanId, endsWith('_scan'));
      expect(cachedResult.chatMessageId, isNot('original-turn'));
      expect(cachedResult.chatMessageId, isNotNull);
      final message = verify(() => chat.saveMessage(captureAny())).captured.single as ChatMessage;
      final restored = ChatMessage.fromMap(message.toMap());
      expect(restored.scanData?.scanId, scanId);
      expect(message.mealLogs, hasLength(1));
      expect(message.mealLogs.single.scanId, scanId);
      expect(message.mealLogs.single.journalEntryId, 'cached-meal-id');
      expect(message.mealLogs.single.createdAt, cachedResult.createdAt);
      verify(
        () => history.trySaveToScanHistory(
          any(),
          userImageUrl: any(named: 'userImageUrl'),
          scanId: scanId,
        ),
      ).called(1);
      verify(() => history.logMeal(any(), docId: '${scanId}_meal')).called(1);
      verifyNever(() => history.logSymptom(any(), docId: any(named: 'docId')));
    });

    test('fresh hit records a chat message + cached analytics event', () async {
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => _cachedScan());

      await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const []);

      final chatMsg = verify(() => chat.saveMessage(captureAny())).captured.single as ChatMessage;
      expect(chatMsg.scanData, isNotNull);
      final params =
          verify(
                () => analytics.logEvent(
                  name: 'scan_performed',
                  parameters: captureAny(named: 'parameters'),
                ),
              ).captured.single
              as Map;
      expect(params['source'], 'barcode_cache');
    });

    test('re-flagging unions stored AI flags with current-sensitivity matches', () async {
      when(() => history.getLatestScanByBarcode(any())).thenAnswer((_) async => _cachedScan());

      final result = await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const ['Milk', 'Sesame']);

      expect(result, isNotNull);
      // 'Whey' (stored AI flag) is never dropped; 'Milk' matches the 'Milk
      // powder' ingredient; 'Sesame' matches nothing and adds nothing.
      expect(result!.flaggedIngredients, containsAll(['Whey', 'Milk']));
      expect(result.flaggedIngredients, isNot(contains('Sesame')));
    });

    test('empty barcode never touches history', () async {
      final result = await repo.getCachedBarcodeScan(barcode: '', sensitivities: const []);

      expect(result, isNull);
      verifyNever(() => history.getLatestScanByBarcode(any()));
    });

    test('history errors resolve to null (cache never breaks scanning)', () async {
      when(() => history.getLatestScanByBarcode(any())).thenThrow(Exception('offline'));

      final result = await repo.getCachedBarcodeScan(barcode: '111222333', sensitivities: const []);

      expect(result, isNull);
    });
  });
}
