import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class ChatAttachment extends Equatable {
  const ChatAttachment({required this.id, required this.bytes, required this.source});

  /// Client-side unique identifier (drives remove/preview keys).
  final String id;

  /// Compressed image bytes, ready for upload + vision request.
  final Uint8List bytes;

  /// Where the image came from: 'gallery' | 'label' | 'food' | 'menu'.
  final String source;

  @override
  List<Object?> get props => [id, source];
}
