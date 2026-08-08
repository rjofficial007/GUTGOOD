import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  ChatRepositoryImpl({required ChatFirestoreService firestoreService, required AiService aiService}) : _firestoreService = firestoreService, _aiService = aiService;
  final ChatFirestoreService _firestoreService;
  final AiService _aiService;

  @override
  Future<ChatMessage> saveMessage(ChatMessage message) async {
    final firestoreId = await _firestoreService.saveMessage(message);
    return message.copyWith(firestoreId: firestoreId);
  }

  @override
  Future<void> deleteMessage(ChatMessage message) async {
    final id = message.firestoreId;
    if (id != null) {
      await _firestoreService.deleteMessage(id);
    }
  }

  @override
  Future<void> updateMessageFeedback(ChatMessage message, String feedback) async {
    if (message.firestoreId != null) {
      await _firestoreService.updateMessageFeedback(message.firestoreId!, feedback);
    }
  }

  @override
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images}) =>
      _aiService.sendMessageStream(systemInstruction: systemInstruction, history: history, userText: userText, images: images);
}
