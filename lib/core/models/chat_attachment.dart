import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A pending image attachment in the chat composer.
///
/// ChatGPT interaction model (PRD §6.1): selecting an image must NOT send it.
/// Attachments live in the composer as previews — fully removable and editable —
/// until the user explicitly presses Send, at which point the text prompt and
/// all attachments leave together in a single AI request.
class ChatAttachment extends Equatable {
  /// Client-side unique identifier (drives remove/preview keys).
  final String id;

  /// Compressed image bytes, ready for upload + vision request.
  final Uint8List bytes;

  /// Where the image came from: 'gallery' | 'label' | 'food' | 'menu'.
  final String source;

  const ChatAttachment({required this.id, required this.bytes, required this.source});

  @override
  List<Object?> get props => [id, source];
}
