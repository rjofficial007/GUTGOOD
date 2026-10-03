import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/features/chat/data/repositories/chat_repository_impl.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/food_image_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockChatFirestoreService extends Mock implements ChatFirestoreService {}

class MockAiService extends Mock implements AiClient {}

class MockStreakService extends Mock implements StreakService {}

class MockFoodImageService extends Mock implements FoodImageService {}

void main() {
  late MockChatFirestoreService firestore;
  late MockFoodImageService foodImages;
  late ChatRepositoryImpl repository;

  setUp(() {
    firestore = MockChatFirestoreService();
    foodImages = MockFoodImageService();
    repository = ChatRepositoryImpl(firestoreService: firestore, aiService: MockAiService(), streakService: MockStreakService(), foodImages: foodImages);

    when(() => firestore.deleteMessage(any())).thenAnswer((_) async {});
    when(
      () => foodImages.removeLink(
        hash: any(named: 'hash'),
        kind: any(named: 'kind'),
        id: any(named: 'id'),
      ),
    ).thenAnswer((_) async {});
  });

  ChatMessage message({String? firestoreId = 'f1', List<String> hashes = const [], List<String> urls = const []}) =>
      ChatMessage(localId: 'm1', role: 'user', text: 'hi', firestoreId: firestoreId, imageUrls: urls, imageHashes: hashes, createdAt: DateTime.now());

  group('ChatRepositoryImpl.deleteMessage (§E unlink)', () {
    test('deletes the doc then unlinks each persisted hash', () async {
      await repository.deleteMessage(message(hashes: ['aaaabbbbccccdddd', 'eeeeffff00001111']));

      verify(() => firestore.deleteMessage('f1')).called(1);
      verify(() => foodImages.removeLink(hash: 'aaaabbbbccccdddd', kind: 'chat', id: 'f1')).called(1);
      verify(() => foodImages.removeLink(hash: 'eeeeffff00001111', kind: 'chat', id: 'f1')).called(1);
    });

    test('falls back to URL parsing for pre-registry messages', () async {
      await repository.deleteMessage(message(urls: ['https://x/food_images/aaaabbbbccccdddd.jpg', 'https://x/food_images/1718035200000.jpg']));

      verify(() => foodImages.removeLink(hash: 'aaaabbbbccccdddd', kind: 'chat', id: 'f1')).called(1);
      verifyNever(
        () => foodImages.removeLink(
          hash: '1718035200000',
          kind: any(named: 'kind'),
          id: any(named: 'id'),
        ),
      );
    });

    test('local-only messages touch nothing', () async {
      await repository.deleteMessage(message(firestoreId: null, hashes: ['aaaabbbbccccdddd']));

      verifyNever(() => firestore.deleteMessage(any()));
      verifyNever(
        () => foodImages.removeLink(
          hash: any(named: 'hash'),
          kind: any(named: 'kind'),
          id: any(named: 'id'),
        ),
      );
    });
  });
}
