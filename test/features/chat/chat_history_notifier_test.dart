import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/logs/data/services/domain_event_persister.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}

class MockHistoryFirestoreService extends Mock
    implements HistoryFirestoreService {}

class MockAiService extends Mock implements AiClient {}

class MockAppStateService extends Mock implements AppStateService {}

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUsageService extends Mock implements UsageService {}

class MockDomainEventPersister extends Mock implements DomainEventPersister {}

void main() {
  late ChatHistoryNotifier notifier;
  late MockChatRepository repository;
  late MockChatFirestoreService chatFirestoreService;
  late MockAuthFirestoreService authFirestoreService;
  late MockHistoryFirestoreService historyFirestoreService;
  late MockAiService aiService;
  late MockAppStateService appStateService;
  late MockSharedPreferences prefs;
  late MockFirebaseAuth auth;
  late MockUsageService usageService;
  late MockDomainEventPersister domainEventPersister;
  late StreamController<List<ChatMessage>> controller;

  setUpAll(() {
    registerFallbackValue(
      SymptomLog(symptom: 'Test symptom', createdAt: DateTime(2026)),
    );
    registerFallbackValue(
      ChatMessage(
        localId: 'test-message',
        role: 'user',
        text: 'Test message',
        createdAt: DateTime(2026),
      ),
    );
  });

  setUp(() {
    repository = MockChatRepository();
    chatFirestoreService = MockChatFirestoreService();
    authFirestoreService = MockAuthFirestoreService();
    historyFirestoreService = MockHistoryFirestoreService();
    aiService = MockAiService();
    appStateService = MockAppStateService();
    prefs = MockSharedPreferences();
    auth = MockFirebaseAuth();
    final user = MockUser();
    when(() => user.uid).thenReturn('user');
    when(() => auth.currentUser).thenReturn(user);
    usageService = MockUsageService();
    domainEventPersister = MockDomainEventPersister();
    controller = StreamController<List<ChatMessage>>.broadcast();

    // Default stubs
    when(
      () => appStateService.profileUpdated,
    ).thenReturn(ValueNotifier<bool>(false));
    when(
      () => appStateService.sessionReset,
    ).thenReturn(ValueNotifier<bool>(false));
    when(
      () => appStateService.chatUpdated,
    ).thenReturn(ValueNotifier<bool>(false));
    when(
      () => auth.authStateChanges(),
    ).thenAnswer((_) => Stream.value(MockUser()));
    when(
      () => authFirestoreService.getUserMetadata(),
    ).thenAnswer((_) async => null);
    when(() => prefs.getStringList(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);
    when(
      () => chatFirestoreService.getMessagesStream(limit: any(named: 'limit')),
    ).thenAnswer((_) => controller.stream);
    when(() => usageService.canSummarize()).thenAnswer((_) async => true);

    notifier = ChatHistoryNotifier(
      repository: repository,
      chatFirestoreService: chatFirestoreService,
      authFirestoreService: authFirestoreService,
      historyFirestoreService: historyFirestoreService,
      domainEventPersister: domainEventPersister,
      aiService: aiService,
      appStateService: appStateService,
      prefs: prefs,
      auth: auth,
      usageService: usageService,
    );
  });

  tearDown(() async {
    await controller.close();
  });

  group('ChatHistoryNotifier - Optimistic UI', () {
    test('addOptimisticMessage adds message to the list', () {
      final msg = ChatMessage(
        localId: '123',
        role: 'user',
        text: 'hello',
        createdAt: DateTime.now(),
      );

      notifier.addOptimisticMessage(msg);

      expect(notifier.messages.length, 1);
      expect(notifier.messages.first.localId, '123');
    });

    test('removeMessage removes message by localId', () {
      final msg = ChatMessage(
        localId: '123',
        role: 'user',
        text: 'hello',
        createdAt: DateTime.now(),
      );
      notifier.addOptimisticMessage(msg);
      expect(notifier.messages.length, 1);

      notifier.removeMessage('123');

      expect(notifier.messages.isEmpty, true);
    });

    test('replaceMessage updates existing message', () {
      final msg = ChatMessage(
        localId: '123',
        role: 'user',
        text: 'hello',
        createdAt: DateTime.now(),
      );
      notifier.addOptimisticMessage(msg);

      final next = msg.copyWith(text: 'updated');
      notifier.replaceMessage('123', next);

      expect(notifier.messages.first.text, 'updated');
    });
  });

  group('ChatHistoryNotifier - Firestore Sync', () {
    test('Snapshot update clears optimistic messages once confirmed', () async {
      final msg = ChatMessage(
        localId: '123',
        role: 'user',
        text: 'hello',
        createdAt: DateTime.now(),
      );
      notifier.addOptimisticMessage(msg);

      // Simulate Firestore stream emitting the confirmed message
      final serverMsg = msg.copyWith(firestoreId: 'cloud_123');
      controller.add([serverMsg]);

      // Give stream time to process
      await Future.delayed(const Duration(milliseconds: 50));

      expect(notifier.messages.length, 1);
      expect(notifier.messages.first.firestoreId, 'cloud_123');
    });

    test(
      'Server echo of an image turn keeps local bytes until URLs hydrate',
      () async {
        final bytes = Uint8List.fromList([1, 2, 3, 4]);
        final msg = ChatMessage(
          localId: 'img1',
          role: 'user',
          text: '',
          localImages: [bytes],
          isSending: true,
          createdAt: DateTime.now(),
        );
        notifier.addOptimisticMessage(msg);

        // Server confirms the save before the Storage upload finishes: no URLs yet.
        controller.add([
          msg.copyWith(
            firestoreId: 'cloud_img1',
            clearLocalImages: true,
            isSending: false,
          ),
        ]);
        await Future.delayed(const Duration(milliseconds: 50));

        final shown = notifier.messages.first;
        expect(shown.firestoreId, 'cloud_img1');
        expect(shown.localImages, [bytes]);
        expect(shown.isSending, isTrue);

        // Once remote URLs land, the server version wins and local bytes drop.
        controller.add([
          msg.copyWith(
            firestoreId: 'cloud_img1',
            imageUrls: ['https://x/y.jpg'],
            clearLocalImages: true,
            isSending: false,
          ),
        ]);
        await Future.delayed(const Duration(milliseconds: 50));

        final hydrated = notifier.messages.first;
        expect(hydrated.imageUrls, ['https://x/y.jpg']);
        expect(hydrated.localImages, isNull);
      },
    );
  });

  group('ChatHistoryNotifier - Summary batching (K-6)', () {
    ChatMessage msg(String id) => ChatMessage(
      localId: id,
      role: 'user',
      text: 'text $id',
      createdAt: DateTime.now(),
    );

    test(
      'skips the AI call when fewer than 4 messages newly aged out',
      () async {
        for (var i = 0; i < 7; i++) {
          notifier.addOptimisticMessage(msg('m$i'));
        }

        await notifier.precomputeSummary();

        verifyNever(
          () => aiService.summarizeHistory(
            any(),
            previousSummary: any(named: 'previousSummary'),
          ),
        );
        expect(notifier.cachedSummary, isNull);
      },
    );

    test('summarizes at 4+ newly aged out, then waits for 4 more', () async {
      when(
        () => aiService.summarizeHistory(
          any(),
          previousSummary: any(named: 'previousSummary'),
        ),
      ).thenAnswer((_) async => 's1');
      for (var i = 0; i < 10; i++) {
        notifier.addOptimisticMessage(msg('m$i'));
      }

      await notifier.precomputeSummary();

      verify(
        () => aiService.summarizeHistory(
          any(),
          previousSummary: any(named: 'previousSummary'),
        ),
      ).called(1);
      expect(notifier.cachedSummary, 's1');

      // Two more turns age out — below the batch threshold, no second call.
      notifier
        ..addOptimisticMessage(msg('m10'))
        ..addOptimisticMessage(msg('m11'));
      await notifier.precomputeSummary();

      verifyNever(
        () => aiService.summarizeHistory(any(), previousSummary: 's1'),
      );
    });

    test(
      'skips the AI call when system quota is reserved for classification',
      () async {
        when(() => usageService.canSummarize()).thenAnswer((_) async => false);
        for (var i = 0; i < 10; i++) {
          notifier.addOptimisticMessage(msg('m$i'));
        }

        await notifier.precomputeSummary();

        verifyNever(
          () => aiService.summarizeHistory(
            any(),
            previousSummary: any(named: 'previousSummary'),
          ),
        );
        expect(notifier.cachedSummary, isNull);
      },
    );
  });

  test(
    'a timing sheet from a cleared chat cannot write into a later session',
    () async {
      final meal = MealLog(
        items: const ['Oats'],
        firestoreId: 'old-meal',
        createdAt: DateTime.now(),
      );
      final message = ChatMessage(
        localId: 'old-turn',
        role: 'ai',
        text: 'Meal logged',
        mealLogs: [meal],
        createdAt: DateTime.now(),
      );
      notifier
        ..addOptimisticMessage(message)
        ..clearHistory();
      expect(
        await notifier.confirmJournalTiming(
          message,
          meal: meal,
          occurredAt: DateTime.now(),
        ),
        isFalse,
      );
    },
  );

  test('auto-matched symptom timing keeps the matched meal name', () async {
    final now = DateTime.now();
    final meal = MealLog(
      items: const ['Oats'],
      firestoreId: 'meal-doc',
      journalEntryId: 'meal-entry',
      createdAt: now,
      occurredAt: now.subtract(const Duration(hours: 1)),
      occurredAtProvenance: OccurrenceProvenance.user,
    );
    final symptom = SymptomLog(
      symptom: 'Bloating',
      firestoreId: 'symptom-doc',
      createdAt: now,
    );
    final message = ChatMessage(
      localId: 'turn',
      role: 'ai',
      text: 'Logged',
      symptomLogs: [symptom],
      createdAt: now,
    );

    when(
      () => historyFirestoreService.getRecentMealLogs(
        since: any(named: 'since'),
        throwOnError: true,
      ),
    ).thenAnswer((_) async => [meal]);
    when(
      () => historyFirestoreService.getRecentScans(
        since: any(named: 'since'),
        throwOnError: true,
      ),
    ).thenAnswer((_) async => []);
    when(
      () => historyFirestoreService.logSymptom(any(), docId: 'symptom-doc'),
    ).thenAnswer((_) async => 'symptom-doc');
    when(
      () => chatFirestoreService.saveMessage(any()),
    ).thenAnswer((_) async => 'turn');
    notifier.addOptimisticMessage(message);

    final saved = await notifier.confirmJournalTiming(
      message,
      symptom: symptom,
      occurredAt: now,
    );

    expect(saved, isTrue);
    final persistedSymptom =
        verify(
              () => historyFirestoreService.logSymptom(
                captureAny(),
                docId: 'symptom-doc',
              ),
            ).captured.single
            as SymptomLog;
    expect(persistedSymptom.journalEntryId, 'meal-entry');
    expect(persistedSymptom.foodName, 'Oats');
  });

  test(
    'confirming a scanned food persists the meal and closes the chat prompt',
    () async {
      final scan = ScanResult(
        productName: 'Oats',
        brand: 'Brand',
        category: 'food',
        source: 'FOOD',
        scanId: 'turn_scan',
        score: 80,
        impactType: ImpactType.positive,
        impact: 'Good',
        createdAt: DateTime.now(),
      );
      final message = ChatMessage(
        localId: 'turn',
        role: 'ai',
        text: 'Analysis',
        scanData: scan,
        createdAt: DateTime.now(),
      );
      final meal = MealLog(
        items: const ['Oats'],
        scanId: 'turn_scan',
        firestoreId: 'turn_meal',
        journalEntryId: 'turn_meal',
        createdAt: scan.createdAt,
      );
      final resolvedScan = scan.copyWith(consumed: true);
      final resolvedMessage = message.copyWith(
        scanData: resolvedScan,
        mealLogs: [meal],
      );

      when(
        () => historyFirestoreService.getScanById('turn_scan'),
      ).thenAnswer((_) async => scan);
      when(
        () => domainEventPersister.persistConfirmedScanMeal(
          resolvedScan,
          chatMessageId: 'turn',
        ),
      ).thenAnswer((_) async => meal);
      when(
        () => historyFirestoreService.trySaveToScanHistory(
          resolvedScan,
          userImageUrl: any(named: 'userImageUrl'),
          scanId: 'turn_scan',
        ),
      ).thenAnswer((_) async => true);
      when(
        () => historyFirestoreService.deleteScanMealProjections(
          chatMessageId: 'turn',
          scanId: 'turn_scan',
          keepMealId: 'turn_meal',
        ),
      ).thenAnswer((_) async {});
      when(
        () => chatFirestoreService.saveMessage(resolvedMessage),
      ).thenAnswer((_) async => 'turn');
      notifier.addOptimisticMessage(message);
      controller.add([message]);
      await Future<void>.delayed(Duration.zero);

      final saveOperation = notifier.resolveScanConsumption(
        message,
        consumed: true,
      );
      expect(notifier.isResolvingScanConsumption(message.localId), isTrue);
      final saved = await saveOperation;

      expect(saved, isTrue);
      expect(notifier.isResolvingScanConsumption(message.localId), isFalse);
      expect(notifier.messages.single.scanData?.consumed, isTrue);
      expect(notifier.messages.single.mealLogs.single.items, ['Oats']);
      // An older Firestore snapshot must not bring the confirmation buttons back.
      controller.add([message]);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.messages.single.scanData?.consumed, isTrue);

      // The persisted echo then confirms the resolution on the server.
      controller.add([resolvedMessage]);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.messages.single.scanData?.consumed, isTrue);
      verify(
        () => domainEventPersister.persistConfirmedScanMeal(
          resolvedScan,
          chatMessageId: 'turn',
        ),
      ).called(1);
    },
  );
}
