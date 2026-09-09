import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// A text message queued while offline, awaiting auto-send on reconnect.
///
/// Images are never queued (bytes don't belong in prefs) — image turns stay
/// online-only and the composer refuses them with `ChatSendError.offline`.
class QueuedMessage {
  const QueuedMessage({required this.id, required this.text, this.hiddenContext, this.source, required this.createdAt});

  factory QueuedMessage.fromJson(Map<String, dynamic> json) => QueuedMessage(
    id: json['id'] as String? ?? '',
    text: json['text'] as String? ?? '',
    hiddenContext: json['hiddenContext'] as String?,
    source: json['source'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  /// Stable identity, also used as the chat `localId` so a failed flush
  /// attempt rolls back onto this same message instead of duplicating it.
  final String id;
  final String text;
  final String? hiddenContext;
  final String? source;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'hiddenContext': hiddenContext, 'source': source, 'createdAt': createdAt.toIso8601String()};

  bool get isValid => id.isNotEmpty && text.isNotEmpty;
}

/// Restart-safe FIFO outbox for offline text sends (audit §E: outbox in prefs).
abstract class ChatOutboxService {
  /// Pending entries, oldest first. Never throws — corrupt prefs read as empty.
  List<QueuedMessage> get pending;
  bool get isEmpty;
  Future<void> enqueue(QueuedMessage message);
  Future<void> dequeue(String id);
  Future<void> clear();
}

class ChatOutboxServiceImpl implements ChatOutboxService {
  ChatOutboxServiceImpl({required SharedPreferences prefs}) : _prefs = prefs;

  final SharedPreferences _prefs;

  static const _key = 'chat_text_outbox_v1';

  @override
  List<QueuedMessage> get pending {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list.whereType<Map<String, dynamic>>().map(QueuedMessage.fromJson).where((m) => m.isValid).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  bool get isEmpty => pending.isEmpty;

  @override
  Future<void> enqueue(QueuedMessage message) async {
    final entries = pending.where((m) => m.id != message.id).toList()..add(message);
    await _persist(entries);
  }

  @override
  Future<void> dequeue(String id) async {
    await _persist(pending.where((m) => m.id != id).toList());
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_key);
  }

  Future<void> _persist(List<QueuedMessage> entries) async {
    await _prefs.setString(_key, jsonEncode(entries.map((m) => m.toJson()).toList()));
  }
}
