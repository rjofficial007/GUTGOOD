import 'dart:typed_data';

import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';

class SendMessageStreamUseCase {

  SendMessageStreamUseCase(this._repository);
  final ChatRepository _repository;

  Stream<String> call({
    required String systemInstruction,
    required List<ChatMessage> history,
    required String userText,
    List<Uint8List>? images,
  }) => _repository.sendMessageStream(
      systemInstruction: systemInstruction,
      history: history,
      userText: userText,
      images: images,
    );
}
