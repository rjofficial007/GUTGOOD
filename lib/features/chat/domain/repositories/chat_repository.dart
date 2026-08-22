import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';

abstract class ChatRepository {
  Future<ChatMessage> saveMessage(ChatMessage message);
  Future<List<ChatMessage>> getOlderMessages({required int limit, required DateTime before});
  Future<void> deleteMessage(ChatMessage message);
  Future<void> updateMessageFeedback(ChatMessage message, String feedback);
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images});
}
