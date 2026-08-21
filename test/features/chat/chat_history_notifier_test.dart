import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockChatRepository extends Mock implements ChatRepository {}
class MockChatFirestoreService extends Mock implements ChatFirestoreService {}
class MockAuthFirestoreService extends Mock implements AuthFirestoreService {}
class MockAiService extends Mock implements AiService {}
class MockAppStateService extends Mock implements AppStateService {}
class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}

void main() {
  late ChatHistoryNotifier notifier;
  late MockChatRepository repository;
  late MockChatFirestoreService chatFirestoreService;
  late MockAuthFirestoreService authFirestoreService;
  late MockAiService aiService;
  late MockAppStateService appStateService;
  late MockSharedPreferences prefs;
  late MockFirebaseAuth auth;
  late StreamController<List<ChatMessage>> controller;

  setUp(() {
    repository = MockChatRepository();
    chatFirestoreService = MockChatFirestoreService();
    authFirestoreService = MockAuthFirestoreService();
    aiService = MockAiService();
    appStateService = MockAppStateService();
    prefs = MockSharedPreferences();
    auth = MockFirebaseAuth();
    controller = StreamController<List<ChatMessage>>.broadcast();

    // Default stubs
    when(() => appStateService.profileUpdated).thenReturn(ValueNotifier<bool>(false));
    when(() => appStateService.sessionReset).thenReturn(ValueNotifier<bool>(false));
    when(() => appStateService.chatUpdated).thenReturn(ValueNotifier<bool>(false));
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(MockUser()));
    when(() => authFirestoreService.getUserMetadata()).thenAnswer((_) async => null);
    when(() => prefs.getStringList(any())).thenReturn(null);
    when(() => prefs.getBool(any())).thenReturn(null);
    when(() => prefs.getString(any())).thenReturn(null);
    when(() => chatFirestoreService.getMessagesStream(limit: any(named: 'limit')))
        .thenAnswer((_) => controller.stream);

    notifier = ChatHistoryNotifier(
      repository: repository,
      chatFirestoreService: chatFirestoreService,
      authFirestoreService: authFirestoreService,
      aiService: aiService,
      appStateService: appStateService,
      prefs: prefs,
      auth: auth,
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
        time: DateTime.now(),
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
        time: DateTime.now(),
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
        time: DateTime.now(),
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
        time: DateTime.now(),
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
  });
}
