part of 'chat_composer_notifier.dart';

/// Chat history-window and pinned-context preparation.

const _chatMaxContextMessages = 12;

extension ChatComposerContext on ChatComposerNotifier {
  /// Full turns in the model context (K-4/P2-2: cut from 25). What falls out
  /// is covered by the rolling summary (narrative) + pinned entities (nouns).
  /// Chronological, sendable messages before windowing. Shared by
  /// [_buildHistory] (keeps the tail) and [_pinnedEntities] (mines the head).
  List<ChatMessage> _contextCandidates() {
    final all = _historyNotifier.messages.reversed.toList();
    final activeId = _activeAiLocalId;

    return all.where((m) {
      if (m.localId == activeId) return false;
      if (m.sendFailed) return false;
      if (m.role == 'ai' && m.text.isEmpty && m.scanData == null) return false;
      if (m.role == 'ai' && m.errorKind == ChatErrorKind.quota) return false;
      return m.text.isNotEmpty || m.scanData != null;
    }).toList();
  }

  List<ChatMessage> _buildHistory() {
    var chronological = _contextCandidates().map((m) {
      final cleanText = m.text
          .replaceAll(RegExp(r'\[SCAN\].*?\[/SCAN\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[MEAL\].*?\[/MEAL\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[SYMPTOM\].*?\[/SYMPTOM\]', dotAll: true), '')
          .replaceAll(RegExp(r'\[SWAPS\].*?\[/SWAPS\]', dotAll: true), '')
          .trim();

      if (cleanText.isEmpty && m.scanData != null) {
        return m.copyWith(text: 'I scanned ${m.scanData!.productName}.');
      }
      return m.copyWith(text: cleanText);
    }).toList();

    if (chronological.isNotEmpty && chronological.last.role == 'user' && chronological.last.text == _lastUserText) {
      chronological = chronological.sublist(0, chronological.length - 1);
    }

    if (chronological.length > _chatMaxContextMessages) {
      chronological = chronological.sublist(chronological.length - _chatMaxContextMessages);
    }
    return chronological;
  }

  /// Entity names from messages outside the context window, or null when the
  /// whole conversation fits (or the dropped prefix names nothing).
  String? _pinnedEntities() {
    final candidates = _contextCandidates();
    if (candidates.length <= _chatMaxContextMessages) return null;
    return ChatPromptContext.buildPinnedEntities(candidates.sublist(0, candidates.length - _chatMaxContextMessages));
  }
}
