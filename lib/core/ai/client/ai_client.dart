import 'dart:typed_data';

import 'package:gutgood/core/models/chat/chat_message.dart';

abstract interface class AiClient {
  Stream<String> sendMessageStream({
    required String systemInstruction,
    required List<ChatMessage> history,
    required String userText,
    List<Uint8List>? images,
    String mode = 'stream',
    String? intent,
    int? promptVersion,
  });

  Future<String> generateContent({required String prompt, String? systemInstruction, Uint8List? imageBytes, String usageType, String mode = 'json', int? promptVersion});

  Future<String> summarizeHistory(List<ChatMessage> history, {String? previousSummary});

  /// P3-4: whether the most recently completed call was truncated
  /// (middle-out input cut, or a `finish_reason: length` output cut).
  bool get lastResponseTruncated;

  /// J-4 §17: proxy echo of the sent `promptVersion` (null when the caller
  /// didn't send one, or the stream broke before the meta frame).
  int? get lastPromptVersion;

  /// J-4 §17: serving model id echoed by the proxy (may differ from the
  /// requested model when the allowlist substitutes).
  String? get lastServedModel;
}

