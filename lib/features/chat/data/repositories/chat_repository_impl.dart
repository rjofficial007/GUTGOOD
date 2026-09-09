import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/food_image.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/food_image_firestore_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/image_hash.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatFirestoreService firestoreService, required AiService aiService, required StreakService streakService, required FoodImageService foodImages})
    : _firestoreService = firestoreService,
      _aiService = aiService,
      _streakService = streakService,
      _foodImages = foodImages;
  final ChatFirestoreService _firestoreService;
  final AiService _aiService;
  final StreakService _streakService;
  final FoodImageService _foodImages;

  @override
  Future<ChatMessage> saveMessage(ChatMessage message) async {
    final firestoreId = await _firestoreService.saveMessage(message);
    if (message.role == 'user') {
      await _streakService.markActivityToday();
    }
    return message.copyWith(firestoreId: firestoreId);
  }

  @override
  Future<List<ChatMessage>> getOlderMessages({required int limit, required DateTime before}) =>
      _firestoreService.getOlderMessages(limit: limit, before: before);

  @override
  Future<void> deleteMessage(ChatMessage message) async {
    final id = message.firestoreId;
    if (id != null) {
      await _firestoreService.deleteMessage(id);
      // Drop this message's photo links; hash list first, URL parse as
      // fallback for messages saved before imageHashes existed.
      final hashes = message.imageHashes.isNotEmpty
          ? message.imageHashes
          : message.imageUrls.map(imageHashFromFoodUrl).whereType<String>().toList();
      for (final hash in hashes) {
        await _foodImages.removeLink(hash: hash, kind: FoodImageLinks.kindChat, id: id);
      }
    }
  }

  @override
  Future<void> updateMessageFeedback(ChatMessage message, String feedback) async {
    if (message.firestoreId != null) {
      await _firestoreService.updateMessageFeedback(message.firestoreId!, feedback);
    }
  }

  @override
  Future<void> patchMessageImageUrls({required String localId, required List<String> imageUrls}) =>
      _firestoreService.patchMessageImageUrls(localId: localId, imageUrls: imageUrls);

  @override
  Future<void> patchMessageImageHashes({required String localId, required List<String> imageHashes}) =>
      _firestoreService.patchMessageImageHashes(localId: localId, imageHashes: imageHashes);

  @override
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images, String? intent, int? promptVersion}) =>
      _aiService.sendMessageStream(systemInstruction: systemInstruction, history: history, userText: userText, images: images, intent: intent, promptVersion: promptVersion);

  @override
  bool get lastResponseTruncated => _aiService.lastResponseTruncated;

  @override
  int? get lastPromptVersion => _aiService.lastPromptVersion;

  @override
  String? get lastServedModel => _aiService.lastServedModel;
}
