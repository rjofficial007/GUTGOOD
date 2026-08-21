import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/chat/domain/usecases/send_message_stream_usecase.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:mocktail/mocktail.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatHistoryNotifier extends Mock implements ChatHistoryNotifier {}
class MockAiService extends Mock implements AiService {}
class MockStorageService extends Mock implements StorageService {}
class MockOffService extends Mock implements OffService {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockInternetConnectionChecker extends Mock implements InternetConnectionChecker {}
class MockSendMessageStreamUseCase extends Mock implements SendMessageStreamUseCase {}
class MockProcessChatTagUseCase extends Mock implements ProcessChatTagUseCase {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAppStateService extends Mock implements AppStateService {}

void main() {
  late ChatComposerNotifier notifier;
  late MockChatRepository repository;
  late MockChatHistoryNotifier historyNotifier;
  late MockAiService aiService;
  late MockStorageService storageService;
  late MockOffService offService;
  late MockFirebaseAuth auth;
  late MockInternetConnectionChecker connectionChecker;
  late MockSendMessageStreamUseCase sendMessageStreamUseCase;
  late MockProcessChatTagUseCase processChatTagUseCase;
  late MockAnalyticsService analyticsService;
  late MockAppStateService appStateService;

  setUpAll(() {
    registerFallbackValue(ChatMessage(localId: '', role: '', text: '', time: DateTime.now()));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    repository = MockChatRepository();
    historyNotifier = MockChatHistoryNotifier();
    aiService = MockAiService();
    storageService = MockStorageService();
    offService = MockOffService();
    auth = MockFirebaseAuth();
    connectionChecker = MockInternetConnectionChecker();
    sendMessageStreamUseCase = MockSendMessageStreamUseCase();
    processChatTagUseCase = MockProcessChatTagUseCase();
    analyticsService = MockAnalyticsService();
    appStateService = MockAppStateService();

    when(() => connectionChecker.isInternetAvailable).thenReturn(ValueNotifier<bool>(true));
    when(() => appStateService.sessionReset).thenReturn(ValueNotifier<bool>(false));

    notifier = ChatComposerNotifier(
      repository: repository,
      historyNotifier: historyNotifier,
      aiService: aiService,
      storageService: storageService,
      offService: offService,
      auth: auth,
      connectionChecker: connectionChecker,
      sendMessageStreamUseCase: sendMessageStreamUseCase,
      processChatTagUseCase: processChatTagUseCase,
      analyticsService: analyticsService,
      appStateService: appStateService,
    );
  });

  group('ChatComposerNotifier - Attachments', () {
    test('addAttachment compresses and adds image', () async {
      final bytes = Uint8List(10);
      when(() => storageService.compressImage(any())).thenAnswer((_) async => bytes);
      when(() => analyticsService.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters')))
          .thenAnswer((_) async {});

      final result = await notifier.addAttachment(bytes);

      expect(result, true);
      expect(notifier.pendingAttachments.length, 1);
      verify(() => storageService.compressImage(bytes)).called(1);
    });

    test('removeAttachment removes specific id', () async {
      final bytes = Uint8List(10);
      when(() => storageService.compressImage(any())).thenAnswer((_) async => bytes);
      when(() => analyticsService.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters')))
          .thenAnswer((_) async {});
      
      await notifier.addAttachment(bytes);
      final id = notifier.pendingAttachments.first.id;
      
      notifier.removeAttachment(id);
      
      expect(notifier.pendingAttachments.isEmpty, true);
    });
  });

  group('ChatComposerNotifier - Sending', () {
    test('send returns offline error when no internet', () async {
      when(() => connectionChecker.isInternetAvailable).thenReturn(ValueNotifier<bool>(false));

      final result = await notifier.send(text: 'hello');

      expect(result, ChatSendError.offline);
    });

    test('send returns empty error when no text and no attachments', () async {
      final result = await notifier.send(text: '');

      expect(result, ChatSendError.empty);
    });
  });
}
