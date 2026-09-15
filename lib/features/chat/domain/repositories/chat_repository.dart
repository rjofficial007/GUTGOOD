import 'dart:typed_data';

import 'package:gutgood/core/models/chat/chat_message.dart';

abstract class ChatRepository {
  Future<ChatMessage> saveMessage(ChatMessage message);
  Future<List<ChatMessage>> getOlderMessages({required int limit, required DateTime before});
  Future<void> deleteMessage(ChatMessage message);
  Future<void> updateMessageFeedback(ChatMessage message, String feedback);
  Future<void> patchMessageImageUrls({required String localId, required List<String> imageUrls});
  Future<void> patchMessageImageHashes({required String localId, required List<String> imageHashes});
  Stream<String> sendMessageStream({required String systemInstruction, required List<ChatMessage> history, required String userText, List<Uint8List>? images, String? intent, int? promptVersion});

  /// P3-4: whether the most recently completed stream was truncated
  /// (proxied from [AiService.lastResponseTruncated]).
  bool get lastResponseTruncated;

  /// J-4 §17: proxy echo of the sent prompt version (proxied from AiService).
  int? get lastPromptVersion;

  /// J-4 §17: serving model id echoed by the proxy (proxied from AiService).
  String? get lastServedModel;
}
