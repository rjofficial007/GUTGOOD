import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/chat/application/usecases/persist_ai_response_usecase.dart';
import 'package:gutgood/features/chat/data/services/chat_outbox_service.dart';
import 'package:gutgood/features/chat/data/services/image_upload_outbox.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/services/chat_prompt_context.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/storage_service.dart';
import 'package:gutgood/infrastructure/open_food_facts/off_service.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}

class MockChatHistoryNotifier extends Mock implements ChatHistoryNotifier {}

class MockAiService extends Mock implements AiClient {}

class MockAiClassifierService extends Mock implements AiClassifierService {}

class MockStorageService extends Mock implements StorageService {}

class MockOffService extends Mock implements OffService {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockInternetConnectionChecker extends Mock implements InternetConnectionChecker {}

class MockSendMessageStreamUseCase extends Mock implements SendMessageStreamUseCase {}

class MockProcessChatTagUseCase extends Mock implements ProcessChatTagUseCase {}

class MockPersistAiResponseUseCase extends Mock implements PersistAiResponseUseCase {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAppStateService extends Mock implements AppStateService {}

class MockUser extends Mock implements User {}

class MockProfileNotifier extends Mock implements ProfileNotifier {}

class MockChatOutboxService extends Mock implements ChatOutboxService {}

class MockImageUploadOutbox extends Mock implements ImageUploadOutbox {}

class MockFoodImageService extends Mock implements FoodImageService {}

Future<void> _noopRecover(String _, Map<int, RecoveredUpload> _) async {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ChatComposerNotifier notifier;
  late MockChatRepository repository;
  late MockChatHistoryNotifier historyNotifier;
  late MockAiClassifierService aiClassifierService;
  late MockStorageService storageService;
  late MockOffService offService;
  late MockFirebaseAuth auth;
  late MockInternetConnectionChecker connectionChecker;
  late MockSendMessageStreamUseCase sendMessageStreamUseCase;
  late MockProcessChatTagUseCase processChatTagUseCase;
  late MockPersistAiResponseUseCase persistAiResponseUseCase;
  late MockAnalyticsService analyticsService;
  late MockAppStateService appStateService;
  late MockChatOutboxService outboxService;
  late MockImageUploadOutbox uploadOutbox;
  late MockFoodImageService foodImages;

  setUpAll(() {
    registerFallbackValue(ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()));
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<ChatMessage>[]);
    registerFallbackValue(const AiAnalysisResult(text: ''));
    registerFallbackValue(<String>{});
    registerFallbackValue(<String>[]);
    registerFallbackValue(QueuedMessage(id: '', text: '', createdAt: DateTime.now()));
    registerFallbackValue(_noopRecover);
  });

  setUp(() {
    // Stream chunks trigger haptics; swallow the platform-channel call.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
  });

  tearDown(() async {
    await sl.reset();
  });

  setUp(() {
    repository = MockChatRepository();
    historyNotifier = MockChatHistoryNotifier();
    aiClassifierService = MockAiClassifierService();
    storageService = MockStorageService();
    offService = MockOffService();
    auth = MockFirebaseAuth();
    connectionChecker = MockInternetConnectionChecker();
    sendMessageStreamUseCase = MockSendMessageStreamUseCase();
    processChatTagUseCase = MockProcessChatTagUseCase();
    persistAiResponseUseCase = MockPersistAiResponseUseCase();
    analyticsService = MockAnalyticsService();
    appStateService = MockAppStateService();
    outboxService = MockChatOutboxService();
    uploadOutbox = MockImageUploadOutbox();
    foodImages = MockFoodImageService();

    when(() => historyNotifier.messages).thenReturn(<ChatMessage>[]);
    when(() => connectionChecker.isInternetAvailable).thenReturn(ValueNotifier<bool>(true));
    when(() => appStateService.sessionReset).thenReturn(ValueNotifier<bool>(false));
    when(() => outboxService.pending).thenReturn(<QueuedMessage>[]);
    when(() => outboxService.isEmpty).thenReturn(true);
    when(() => uploadOutbox.isEmpty).thenReturn(true);
    if (sl.isRegistered<ProfileNotifier>()) {
      sl.unregister<ProfileNotifier>();
    }
    sl.registerLazySingleton<ProfileNotifier>(MockProfileNotifier.new);
    when(
      () => foodImages.addLink(
        hash: any(named: 'hash'),
        kind: any(named: 'kind'),
        id: any(named: 'id'),
      ),
    ).thenAnswer((_) async {});
    when(() => repository.lastResponseTruncated).thenReturn(false);
    when(() => repository.lastPromptVersion).thenReturn(null);
    when(() => repository.lastServedModel).thenReturn(null);

    notifier = ChatComposerNotifier(
      repository: repository,
      historyNotifier: historyNotifier,
      storageService: storageService,
      offService: offService,
      aiClassifierService: aiClassifierService,
      auth: auth,
      connectionChecker: connectionChecker,
      sendMessageStreamUseCase: sendMessageStreamUseCase,
      processChatTagUseCase: processChatTagUseCase,
      persistAiResponseUseCase: persistAiResponseUseCase,
      analyticsService: analyticsService,
      appStateService: appStateService,
      outboxService: outboxService,
      uploadOutbox: uploadOutbox,
      foodImages: foodImages,
    );
  });

  group('ChatComposerNotifier - See more swaps', () {
    test('uses general suggestions when fewer than four unseen catalog alternatives remain', () async {
      final scan = ScanResult(
        productName: 'Packaged snack',
        brand: '',
        score: 70,
        impactType: ImpactType.neutral,
        impact: 'neutral',
        barcode: '1234567890123',
        category: 'snack',
        createdAt: DateTime(2026),
      );
      final originalMessage = ChatMessage(localId: 'barcode-message', firestoreId: 'barcode-message', role: 'ai', text: 'Here are alternatives.', scanData: scan, createdAt: DateTime.now());
      final messages = <ChatMessage>[originalMessage];
      when(() => historyNotifier.messages).thenReturn(messages);
      when(() => historyNotifier.userGoals).thenReturn(<String>[]);
      when(() => historyNotifier.userSensitivities).thenReturn(<String>[]);
      when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((invocation) {
        messages[0] = invocation.positionalArguments[1] as ChatMessage;
      });
      when(() => repository.saveMessage(any())).thenAnswer((invocation) async => invocation.positionalArguments[0] as ChatMessage);
      when(() => offService.getProduct(scan.barcode!)).thenAnswer((_) async => const OffProduct(productName: 'Packaged snack', categoryTag: 'en:snacks'));
      when(() => offService.getBetterAlternatives(any(), any())).thenAnswer((_) async => const [OffProduct(productName: 'One catalog option', barcode: '9876543210123')]);
      when(
        () => repository.sendMessageStream(
          systemInstruction: any(named: 'systemInstruction'),
          history: any(named: 'history'),
          userText: any(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer(
        (_) => Stream.value(
            '[{"name":"Pear","replaces":"Packaged snack","reason":"Adds fiber.","category":"fruit","tag":"HIGH_FIBER","imageKeyword":"pear",'
          '"benefitTags":["Fiber source"],"structuredBenefits":[{"title":"Fiber","description":"Contains dietary fiber.","icon":"leaf"}],'
          '"whyBetterOption":"Compared with the packaged snack, a whole pear provides fiber; portion size still matters.",'
            '"nutrition":{"calories":80,"protein":"1 g","totalFat":"0 g","fiber":"5 g","basis":"per serving"}},'
            '{"name":"Oats","replaces":"Packaged snack","reason":"Adds whole grains."},'
            '{"name":"Kiwi","replaces":"Packaged snack","reason":"Adds variety."},{"name":"Chia","replaces":"Packaged snack","reason":"Adds fiber."}]',
        ),
      );
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final result = await notifier.handleSeeMoreSwaps(originalMessage);

      expect(result, isNull);
      expect(messages.single.swapData, hasLength(4));
      final pear = messages.single.swapData!.first.alternative!;
      expect(pear.whyBetterOption, contains('whole pear'));
      expect(pear.benefits.single.title, 'Fiber');
      expect(pear.nutrition.hasData, isTrue, reason: 'supplied nutrition should reach the Swap Details screen');
      expect(pear.nutrition.basis, contains('not verified'));
      expect(messages.single.swapData![1].alternative!.nutrition.hasData, isFalse, reason: 'unknown nutrition remains hidden');
      final request = verify(
        () => repository.sendMessageStream(
          systemInstruction: captureAny(named: 'systemInstruction'),
          history: any(named: 'history'),
          userText: captureAny(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).captured;
        expect(request[0], contains('exactly 4 NEW distinct objects'));
        expect(request[0], contains('Return exactly four distinct alternatives'));
        expect(request[0], contains('Match whole-dish type: pizza→pizza'));
        expect(request[0], contains('Set replaces to the exact scanned dish or product'));
        expect(request[0], contains('A missing nutrient never changes type'));
        expect(request[0], contains('Avoid generic health claims and unsupported weight-loss, calorie, symptom-relief, or disease claims'));
      expect(request[1], isNot(contains('availableProducts')));
    });

    test('appends only new swaps to the original AI message without persisting a scan turn', () async {
      const originalSwaps = [
        ProductSwap(title: 'Berry bowl', subtitle: 'More fiber', imageKeyword: 'berries', tag: 'HIGH_FIBER'),
        ProductSwap(title: 'Banana', subtitle: 'Potassium source', imageKeyword: 'banana', tag: 'POTASSIUM'),
        ProductSwap(title: 'Chia pudding', subtitle: 'Fiber source', imageKeyword: 'chia pudding', tag: 'HIGH_FIBER'),
        ProductSwap(title: 'Kiwi', subtitle: 'Vitamin C source', imageKeyword: 'kiwi', tag: 'VITAMIN_C'),
      ];
      const addedSwapsJson = '''[
        {"name":"Coconut milk ice cream","replaces":"Vanilla Ice Cream","reason":"Different base; compare labels.","imageKeyword":"coconut ice cream","tag":"ALTERNATIVE"},
        {"name":"Soy frozen yogurt","replaces":"Vanilla Ice Cream","reason":"Different base; compare labels.","imageKeyword":"soy frozen yogurt","tag":"ALTERNATIVE"},
        {"name":"Oat milk ice cream","replaces":"Vanilla Ice Cream","reason":"Different base; compare labels.","imageKeyword":"oat ice cream","tag":"ALTERNATIVE"},
        {"name":"Banana nice cream","replaces":"Vanilla Ice Cream","reason":"Fruit base; texture differs.","imageKeyword":"banana nice cream","tag":"ALTERNATIVE"}
      ]''';
      final originalScan = ScanResult(
        productName: 'Vanilla Ice Cream',
        brand: '',
        score: 70,
        impactType: ImpactType.neutral,
        impact: 'A dessert scan.',
        scanId: 'scan-1',
        createdAt: DateTime(2026),
      );
      final originalMessage = ChatMessage(
        localId: 'original-ai-message',
        firestoreId: 'original-ai-message',
        role: 'ai',
        text: 'Here are a few ideas.',
        foodMentions: const ['Vanilla Ice Cream'],
        scanData: originalScan,
        swapData: originalSwaps,
        analysisResult: AiAnalysisResult(text: 'Here are a few ideas.', scan: originalScan, swaps: originalSwaps),
        createdAt: DateTime.now(),
      );
      final messages = <ChatMessage>[originalMessage];
      when(() => historyNotifier.messages).thenReturn(messages);
      when(() => historyNotifier.userGoals).thenReturn(<String>[]);
      when(() => historyNotifier.userSensitivities).thenReturn(<String>[]);
      when(() => historyNotifier.appendScanSwaps(scanId: any(named: 'scanId'), swaps: any(named: 'swaps'))).thenAnswer((_) async => true);
      when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((invocation) {
        final index = messages.indexWhere((message) => message.localId == invocation.positionalArguments[0]);
        if (index >= 0) messages[index] = invocation.positionalArguments[1] as ChatMessage;
      });
      when(() => repository.saveMessage(any())).thenAnswer((invocation) async => (invocation.positionalArguments[0] as ChatMessage).copyWith(firestoreId: 'original-ai-message'));
      when(
        () => repository.sendMessageStream(
          systemInstruction: any(named: 'systemInstruction'),
          history: any(named: 'history'),
          userText: any(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer((_) => Stream.value(addedSwapsJson));
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final result = await notifier.handleSeeMoreSwaps(originalMessage);

      expect(result, isNull);
      expect(messages, hasLength(1));
      expect(messages.single.localId, originalMessage.localId);
      expect(messages.single.scanData!.scanId, 'scan-1');
      expect(messages.single.scanData!.swaps, hasLength(8));
      expect(messages.single.swapData!.map((swap) => swap.title), ['Berry bowl', 'Banana', 'Chia pudding', 'Kiwi', 'Coconut milk ice cream', 'Soy frozen yogurt', 'Oat milk ice cream', 'Banana nice cream']);
      verify(() => historyNotifier.appendScanSwaps(scanId: 'scan-1', swaps: any(named: 'swaps'))).called(1);
      final request = verify(
        () => repository.sendMessageStream(
          systemInstruction: captureAny(named: 'systemInstruction'),
          history: captureAny(named: 'history'),
          userText: captureAny(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).captured;
      expect(request[1], isEmpty, reason: 'pagination sends no redundant chat history');
      expect(request[2], contains('Vanilla Ice Cream'));
      expect(request[2], contains('alreadyShown'));
      verifyNever(() => historyNotifier.addOptimisticMessage(any()));
      verifyNever(
        () => persistAiResponseUseCase.call(
          any(),
          chatMessageId: any(named: 'chatMessageId'),
          imageUrl: any(named: 'imageUrl'),
          source: any(named: 'source'),
          persistedTagBlocks: any(named: 'persistedTagBlocks'),
        ),
      );
    });
  });

  group('ChatComposerNotifier - Attachments', () {
    test('addAttachment compresses and adds image', () async {
      final bytes = Uint8List(10);
      when(() => storageService.compressForAi(any())).thenAnswer((_) async => bytes);
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final result = await notifier.addAttachment(bytes);

      expect(result, true);
      expect(notifier.pendingAttachments.length, 1);
      // Vision input must use the AI profile (~1280 px), not the 320 px
      // Storage thumbnail profile.
      verify(() => storageService.compressForAi(bytes)).called(1);
      verifyNever(() => storageService.compressImage(any()));
    });

    test('removeAttachment removes specific id', () async {
      final bytes = Uint8List(10);
      when(() => storageService.compressForAi(any())).thenAnswer((_) async => bytes);
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await notifier.addAttachment(bytes);
      final id = notifier.pendingAttachments.first.id;

      notifier.removeAttachment(id);

      expect(notifier.pendingAttachments.isEmpty, true);
    });
  });

  group('ChatComposerNotifier - Sending', () {
    test('offline text send queues for auto-send', () async {
      when(() => connectionChecker.isInternetAvailable).thenReturn(ValueNotifier<bool>(false));
      when(() => outboxService.enqueue(any())).thenAnswer((_) async {});
      final added = <ChatMessage>[];
      when(() => historyNotifier.addOptimisticMessage(any())).thenAnswer((inv) {
        added.add(inv.positionalArguments[0] as ChatMessage);
      });

      final result = await notifier.send(text: 'hello', providedUserMsgId: 'u1');

      expect(result, ChatSendError.queued);
      verify(() => outboxService.enqueue(any())).called(1);
      expect(added, hasLength(1));
      expect(added.single.isQueued, isTrue);
      expect(added.single.localId, 'u1');
      verifyNever(
        () => sendMessageStreamUseCase.call(
          systemInstruction: any(named: 'systemInstruction'),
          history: any(named: 'history'),
          userText: any(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      );
    });

    test('offline image send still refuses (bytes never queue)', () async {
      when(() => connectionChecker.isInternetAvailable).thenReturn(ValueNotifier<bool>(false));
      when(() => storageService.compressForAi(any())).thenAnswer((inv) async => inv.positionalArguments[0] as Uint8List);
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});
      await notifier.addAttachment(Uint8List(10));

      final result = await notifier.send(text: 'hello');

      expect(result, ChatSendError.offline);
      verifyNever(() => outboxService.enqueue(any()));
    });

    test('send returns empty error when no text and no attachments', () async {
      final result = await notifier.send(text: '');

      expect(result, ChatSendError.empty);
    });

    for (final failure in ['none', 'parsing', 'persistence']) {
      test('image turn releases loading after upload failure and $failure failure', () async {
        final messages = <ChatMessage>[];

        when(() => auth.currentUser).thenReturn(MockUser());
        when(() => historyNotifier.messages).thenReturn(messages);
        when(() => historyNotifier.userGoals).thenReturn(<String>[]);
        when(() => historyNotifier.userSensitivities).thenReturn(<String>[]);
        when(() => historyNotifier.userLifestyle).thenReturn(<String>[]);
        when(() => historyNotifier.cyclePhase).thenReturn('');
        when(() => historyNotifier.commStyle).thenReturn('');
        when(() => historyNotifier.cachedSummary).thenReturn(null);
        when(() => historyNotifier.addOptimisticMessage(any())).thenAnswer((inv) {
          messages.insert(0, inv.positionalArguments[0] as ChatMessage);
        });
        when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((inv) {
          final idx = messages.indexWhere((m) => m.localId == inv.positionalArguments[0]);
          if (idx != -1) messages[idx] = inv.positionalArguments[1] as ChatMessage;
        });
        when(() => historyNotifier.precomputeSummary()).thenAnswer((_) async {});
        when(() => storageService.compressForAi(any())).thenAnswer((inv) async => inv.positionalArguments[0] as Uint8List);
        when(
          () => uploadOutbox.uploadOrEnqueue(
            bytes: any(named: 'bytes'),
            chatLocalId: any(named: 'chatLocalId'),
            index: any(named: 'index'),
          ),
        ).thenThrow(const SocketException('unreachable'));
        when(
          () => aiClassifierService.classifyImage(
            imageBytes: any(named: 'imageBytes'),
            userText: any(named: 'userText'),
            modeHint: any(named: 'modeHint'),
          ),
        ).thenAnswer((_) async => const AiClassificationResult(imageMode: 'FOOD', intent: 'COMPLETE_ANALYSIS', confidence: 1.0));
        when(() => repository.saveMessage(any())).thenAnswer((inv) async => (inv.positionalArguments[0] as ChatMessage).copyWith(firestoreId: 'f1'));
        when(
          () => sendMessageStreamUseCase.call(
            systemInstruction: any(named: 'systemInstruction'),
            history: any(named: 'history'),
            userText: any(named: 'userText'),
            images: any(named: 'images'),
            intent: any(named: 'intent'),
            promptVersion: any(named: 'promptVersion'),
          ),
        ).thenAnswer((_) => Stream.value('Hello there'));
        when(
          () => processChatTagUseCase.call(
            any(),
            userText: any(named: 'userText'),
            imageUrl: any(named: 'imageUrl'),
            source: any(named: 'source'),
            chatMessageId: any(named: 'chatMessageId'),
            isFinal: any(named: 'isFinal'),
            promptVersion: any(named: 'promptVersion'),
            servedModel: any(named: 'servedModel'),
          ),
        ).thenAnswer((inv) {
          if (failure == 'parsing') throw const FormatException('Malformed AI data');
          return AiAnalysisResult(text: inv.positionalArguments[0] as String);
        });
        when(
          () => persistAiResponseUseCase.call(
            any(),
            chatMessageId: any(named: 'chatMessageId'),
            imageUrl: any(named: 'imageUrl'),
            source: any(named: 'source'),
            persistedTagBlocks: any(named: 'persistedTagBlocks'),
          ),
        ).thenAnswer((inv) async {
          if (failure == 'persistence') throw StateError('Persistence failed');
          return inv.positionalArguments[0] as AiAnalysisResult;
        });
        when(
          () => analyticsService.logEvent(
            name: any(named: 'name'),
            parameters: any(named: 'parameters'),
          ),
        ).thenAnswer((_) async {});

        await notifier.addAttachment(Uint8List(10));
        final result = await notifier.send(text: 'what is this');

        // The turn is accepted and streams from in-memory bytes despite the
        // failed upload — no uploadFailed, no killed turn.
        expect(result, isNull);
        final streamedImages =
            verify(
                  () => sendMessageStreamUseCase.call(
                    systemInstruction: any(named: 'systemInstruction'),
                    history: any(named: 'history'),
                    userText: any(named: 'userText'),
                    images: captureAny(named: 'images'),
                    intent: any(named: 'intent'),
                    promptVersion: any(named: 'promptVersion'),
                  ),
                ).captured.single
                as List<Uint8List>?;
        expect(streamedImages, hasLength(1));

        // The user message was saved immediately (durable) without URLs.
        final userSaves = verify(() => repository.saveMessage(captureAny())).captured.cast<ChatMessage>().where((m) => m.role == 'user').toList();
        expect(userSaves, isNotEmpty);
        expect(userSaves.first.imageUrls, isEmpty);

        // After the background upload fails, the turn still completes: the
        // user message is NOT failed, the AI reply lands, and the upload sits
        // queued (spinner stays) instead of dying.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final userMsg = messages.firstWhere((m) => m.role == 'user');
        expect(userMsg.sendFailed, isFalse, reason: 'a failed upload degrades to local bytes; it must not fail the turn');
        expect(userMsg.isSending, isTrue, reason: 'queued upload keeps the spinner until flushUploads settles it');
        expect(notifier.isLoading, isFalse);
        expect(notifier.isStreaming, isFalse);
        final reply = messages.firstWhere((m) => m.role == 'ai');
        if (failure != 'parsing') expect(reply.text, 'Hello there');
        if (failure != 'none') expect(reply.errorKind, ChatErrorKind.connection);
        verifyNever(() => storageService.uploadFoodImage(any()));
      });
    }

    test('flushUploads hydrates the in-memory message', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final messages = <ChatMessage>[
        ChatMessage(localId: 'u1', role: 'user', text: 'hi', isSending: true, localImages: [bytes], createdAt: DateTime.now()),
      ];
      when(() => historyNotifier.messages).thenReturn(messages);
      when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((inv) {
        final idx = messages.indexWhere((m) => m.localId == inv.positionalArguments[0]);
        if (idx != -1) messages[idx] = inv.positionalArguments[1] as ChatMessage;
      });
      when(() => repository.saveMessage(any())).thenAnswer((inv) async => (inv.positionalArguments[0] as ChatMessage).copyWith(firestoreId: 'f1'));
      when(() => uploadOutbox.isEmpty).thenReturn(false);
      when(() => uploadOutbox.pendingFor(any())).thenReturn(<PendingUpload>[]);
      when(() => uploadOutbox.flush(onRecovered: any(named: 'onRecovered'))).thenAnswer((inv) async {
        final cb = inv.namedArguments[#onRecovered] as Future<void> Function(String, Map<int, RecoveredUpload>);
        await cb('u1', {0: const RecoveredUpload(url: 'https://x/food_images/abcdef0123456789.jpg', hash: 'abcdef0123456789')});
      });

      await notifier.flushUploads();

      final patched = messages.single;
      expect(patched.imageUrls, ['https://x/food_images/abcdef0123456789.jpg']);
      expect(patched.imageHashes, ['abcdef0123456789']);
      expect(patched.isSending, isFalse);
      expect(patched.localImages, isNull);
      verify(() => repository.saveMessage(any())).called(1);
      verify(() => foodImages.addLink(hash: 'abcdef0123456789', kind: 'chat', id: 'f1')).called(1);
      verifyNever(
        () => repository.patchMessageImageUrls(
          localId: any(named: 'localId'),
          imageUrls: any(named: 'imageUrls'),
        ),
      );
    });

    test('flushUploads patches Firestore directly when the message is gone (restart)', () async {
      when(() => historyNotifier.messages).thenReturn(<ChatMessage>[]);
      when(
        () => repository.patchMessageImageUrls(
          localId: any(named: 'localId'),
          imageUrls: any(named: 'imageUrls'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => repository.patchMessageImageHashes(
          localId: any(named: 'localId'),
          imageHashes: any(named: 'imageHashes'),
        ),
      ).thenAnswer((_) async {});
      when(() => uploadOutbox.isEmpty).thenReturn(false);
      when(() => uploadOutbox.flush(onRecovered: any(named: 'onRecovered'))).thenAnswer((inv) async {
        final cb = inv.namedArguments[#onRecovered] as Future<void> Function(String, Map<int, RecoveredUpload>);
        await cb('u1', {0: const RecoveredUpload(url: 'https://x/food_images/abcdef0123456789.jpg', hash: 'abcdef0123456789')});
      });

      await notifier.flushUploads();

      verify(() => repository.patchMessageImageUrls(localId: 'u1', imageUrls: ['https://x/food_images/abcdef0123456789.jpg'])).called(1);
      verify(() => repository.patchMessageImageHashes(localId: 'u1', imageHashes: ['abcdef0123456789'])).called(1);
      verify(() => foodImages.addLink(hash: 'abcdef0123456789', kind: 'chat', id: 'u1')).called(1);
      verifyNever(() => repository.saveMessage(any()));
    });

    test('settled-without-urls stops the spinner but keeps local bytes', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final messages = <ChatMessage>[
        ChatMessage(localId: 'u1', role: 'user', text: 'hi', isSending: true, localImages: [bytes], createdAt: DateTime.now()),
      ];
      when(() => historyNotifier.messages).thenReturn(messages);
      when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((inv) {
        final idx = messages.indexWhere((m) => m.localId == inv.positionalArguments[0]);
        if (idx != -1) messages[idx] = inv.positionalArguments[1] as ChatMessage;
      });
      when(() => repository.saveMessage(any())).thenAnswer((inv) async => (inv.positionalArguments[0] as ChatMessage).copyWith(firestoreId: 'f1'));
      when(() => uploadOutbox.isEmpty).thenReturn(false);
      when(() => uploadOutbox.pendingFor(any())).thenReturn(<PendingUpload>[]);
      when(() => uploadOutbox.flush(onRecovered: any(named: 'onRecovered'))).thenAnswer((inv) async {
        final cb = inv.namedArguments[#onRecovered] as Future<void> Function(String, Map<int, RecoveredUpload>);
        await cb('u1', <int, RecoveredUpload>{});
      });

      await notifier.flushUploads();

      final patched = messages.single;
      expect(patched.isSending, isFalse);
      expect(patched.imageUrls, isEmpty);
      expect(patched.localImages, isNotNull, reason: 'poison/purged photo stays visible session-locally');
    });
  });

  group('ChatComposerNotifier - Context window + pins (K-4)', () {
    ChatMessage textMsg(String id, String text, {List<String> foods = const [], List<String> symptoms = const []}) =>
        ChatMessage(localId: id, role: 'user', text: text, foodMentions: foods, symptomMentions: symptoms, createdAt: DateTime.now());

    test('history window holds 12 and dropped entities pin into the prompt', () async {
      final messages = <ChatMessage>[];
      for (var i = 15; i >= 0; i--) {
        messages.add(textMsg('m$i', i == 0 ? 'oldest-turn-marker' : 'turn $i'));
      }
      messages[messages.length - 1] = textMsg('m0', 'oldest-turn-marker', foods: ['farro-bowl'], symptoms: ['foggy-afternoon']);

      when(() => historyNotifier.messages).thenReturn(messages);
      when(() => historyNotifier.userGoals).thenReturn(<String>[]);
      when(() => historyNotifier.userSensitivities).thenReturn(<String>[]);
      when(() => historyNotifier.userLifestyle).thenReturn(<String>[]);
      when(() => historyNotifier.cyclePhase).thenReturn('');
      when(() => historyNotifier.commStyle).thenReturn('');
      when(() => historyNotifier.cachedSummary).thenReturn(null);
      when(() => historyNotifier.addOptimisticMessage(any())).thenAnswer((inv) {
        messages.insert(0, inv.positionalArguments[0] as ChatMessage);
      });
      when(() => historyNotifier.replaceMessage(any(), any())).thenAnswer((inv) {
        final idx = messages.indexWhere((m) => m.localId == inv.positionalArguments[0]);
        if (idx != -1) messages[idx] = inv.positionalArguments[1] as ChatMessage;
      });
      when(() => historyNotifier.precomputeSummary()).thenAnswer((_) async {});
      when(
        () => aiClassifierService.classifyTextIntent(
          userText: any(named: 'userText'),
          historySummary: any(named: 'historySummary'),
        ),
      ).thenAnswer((_) async => 'COMPLETE_ANALYSIS');
      when(() => repository.saveMessage(any())).thenAnswer((inv) async => (inv.positionalArguments[0] as ChatMessage).copyWith(firestoreId: 'f1'));
      when(
        () => sendMessageStreamUseCase.call(
          systemInstruction: any(named: 'systemInstruction'),
          history: any(named: 'history'),
          userText: any(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).thenAnswer((_) => Stream.value('Hello there'));
      when(
        () => processChatTagUseCase.call(
          any(),
          userText: any(named: 'userText'),
          imageUrl: any(named: 'imageUrl'),
          source: any(named: 'source'),
          chatMessageId: any(named: 'chatMessageId'),
          isFinal: any(named: 'isFinal'),
          promptVersion: any(named: 'promptVersion'),
          servedModel: any(named: 'servedModel'),
        ),
      ).thenAnswer((inv) => AiAnalysisResult(text: inv.positionalArguments[0] as String));
      when(
        () => persistAiResponseUseCase.call(
          any(),
          chatMessageId: any(named: 'chatMessageId'),
          imageUrl: any(named: 'imageUrl'),
          source: any(named: 'source'),
          persistedTagBlocks: any(named: 'persistedTagBlocks'),
        ),
      ).thenAnswer((inv) async => inv.positionalArguments[0] as AiAnalysisResult);
      when(
        () => analyticsService.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      final result = await notifier.send(text: 'new question here');
      await Future<void>.delayed(Duration.zero);

      expect(result, isNull);
      final captured = verify(
        () => sendMessageStreamUseCase.call(
          systemInstruction: captureAny(named: 'systemInstruction'),
          history: captureAny(named: 'history'),
          userText: any(named: 'userText'),
          images: any(named: 'images'),
          intent: any(named: 'intent'),
          promptVersion: any(named: 'promptVersion'),
        ),
      ).captured;
      final history = captured[1] as List<ChatMessage>;
      final instruction = captured[0] as String;

      expect(history, hasLength(12));
      expect(history.map((m) => m.text), contains('turn 15'));
      expect(history.map((m) => m.text).join(), isNot(contains('oldest-turn-marker')));
      expect(instruction, contains('PINNED ENTITIES'));
      expect(instruction, contains('farro-bowl'));
      expect(instruction, contains('foggy-afternoon'));
    });
  });

  group('buildPinnedEntities (K-4)', () {
    test('formats foods, symptoms, and scans; null when empty', () {
      final dropped = [
        ChatMessage(
          localId: 'a',
          role: 'user',
          text: 'x',
          foodMentions: const ['Pizza', '  '],
          symptomMentions: const ['Bloating'],
          mealLogs: [
            MealLog(items: const ['pizza', 'Salad'], createdAt: DateTime.now()),
          ],
          createdAt: DateTime.now(),
        ),
        ChatMessage(
          localId: 'b',
          role: 'ai',
          text: 'y',
          scanData: ScanResult(productName: 'Test Cola', brand: '', score: 50, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()),
          createdAt: DateTime.now(),
        ),
      ];

      expect(ChatPromptContext.buildPinnedEntities(dropped), 'foods: Pizza, Salad\nsymptoms: Bloating\nscans: Test Cola');
      expect(ChatPromptContext.buildPinnedEntities([]), isNull);
      expect(ChatPromptContext.buildPinnedEntities([ChatMessage(localId: 'c', role: 'user', text: 'plain', createdAt: DateTime.now())]), isNull);
    });

    test('dedupes case-insensitively and caps each bucket', () {
      final dropped = [
        ChatMessage(localId: 'a', role: 'user', text: 'x', foodMentions: ['Egg', 'egg', 'EGG', ...List.generate(10, (i) => 'food$i')], createdAt: DateTime.now()),
      ];

      expect(ChatPromptContext.buildPinnedEntities(dropped), 'foods: Egg, food0, food1, food2, food3, food4, food5, food6');
    });
  });
}
