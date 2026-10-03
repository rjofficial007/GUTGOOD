part of 'chat_composer_notifier.dart';

/// Offline outbox and turn-lifecycle workflow.

extension ChatComposerOutbox on ChatComposerNotifier {
  // ===========================================================================
  // OFFLINE OUTBOX — text-only queue, auto-flushed FIFO on reconnect.
  // ===========================================================================

  /// Sends queued messages oldest-first. Safe to call any time: no-ops while
  /// a flush is already running or a turn is in flight (the [_finishTurn]
  /// hook re-triggers it). Entries dequeue only after a fully successful
  /// turn; failed attempts roll back onto the same message so nothing is
  /// lost or duplicated.
  Future<ChatSendError?> flushOutbox() async {
    if (_flushing || _isLoading) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;
    if (_outbox.isEmpty) return null;
    _flushing = true;
    try {
      while (_outbox.pending.isNotEmpty) {
        if (!_connectionChecker.isInternetAvailable.value || _isLoading) return null;
        final ok = await _attemptQueued(_outbox.pending.first);
        if (!ok) return null; // rolled back; stays queued for a later trigger
      }
      return null;
    } finally {
      _flushing = false;
    }
  }

  /// Sends one queued entry under its stable chat id. Returns true only when
  /// the turn fully succeeded (entry dequeued).
  Future<bool> _attemptQueued(QueuedMessage entry) async {
    try {
      // Stale entry: a previous attempt already completed under this id
      // (e.g. after an idle-timeout stop) — drop it, don't resend.
      final existing = _findMessage(entry.id);
      if (existing != null && !existing.isQueued) {
        await _outbox.dequeue(entry.id);
        return true;
      }
      if (existing != null) _historyNotifier.removeMessage(entry.id);

      final error = await send(text: entry.text, hiddenContext: entry.hiddenContext, source: entry.source, providedUserMsgId: entry.id);
      if (error != null) {
        _restoreQueued(entry);
        return false;
      }
      final aiLocalId = _activeAiLocalId;
      if (aiLocalId == null || !await _waitForIdle()) {
        // Turn still running past the timeout: leave the attempt live and
        // stop — the stale check above prevents a duplicate on retry.
        return false;
      }
      final aiMsg = _findMessage(aiLocalId);
      if (aiMsg == null || aiMsg.errorKind != ChatErrorKind.none || (aiMsg.text.isEmpty && aiMsg.scanData == null && aiMsg.swapData == null)) {
        await _rollbackAttempt(entry, aiLocalId);
        return false;
      }
      await _outbox.dequeue(entry.id);
      return true;
    } catch (e) {
      AppLogger.warning('ChatComposer: queued attempt failed, kept in outbox. Error: $e');
      _restoreQueued(entry);
      return false;
    }
  }

  /// Deletes a failed attempt (user + AI messages, plus any partial logs
  /// linked to them) and re-parks the entry as a queued bubble.
  Future<void> _rollbackAttempt(QueuedMessage entry, String aiLocalId) async {
    final userAttempt = _findMessage(entry.id);
    if (userAttempt != null) await _historyNotifier.deleteMessage(userAttempt);
    final aiAttempt = _findMessage(aiLocalId);
    if (aiAttempt != null) await _historyNotifier.deleteMessage(aiAttempt);
    _restoreQueued(entry);
    AppLogger.ai('ChatComposer: queued attempt rolled back, kept in outbox');
  }

  Future<void> _enqueueOffline(String text, {String? hiddenContext, String? source, String? providedId}) async {
    // The entry IS the chat message id: the UI's scroll anchor and the
    // flush attempt both reuse it, so no duplicates can form.
    final entry = QueuedMessage(id: providedId ?? const Uuid().v4(), text: text, hiddenContext: hiddenContext, source: source ?? 'chat', createdAt: DateTime.now());
    await _outbox.enqueue(entry);
    _restoreQueued(entry);
    AppLogger.ai('ChatComposer: queued offline message (${_outbox.pending.length} pending)');
  }

  void _restoreQueued(QueuedMessage entry) {
    if (_findMessage(entry.id) != null) return;
    _historyNotifier.addOptimisticMessage(ChatMessage(localId: entry.id, role: 'user', text: entry.text, isSwap: false, isQueued: true, source: entry.source, createdAt: entry.createdAt));
  }

  void _rehydrateOutbox() {
    for (final entry in _outbox.pending) {
      _restoreQueued(entry);
    }
  }

  void _onConnectivityChanged() {
    final online = _connectionChecker.isInternetAvailable.value;
    final restored = online && !_connectivityWasOnline;
    _connectivityWasOnline = online;
    if (restored && _outbox.pending.isNotEmpty) {
      AppLogger.ai('ChatComposer: connection restored, flushing ${_outbox.pending.length} queued message(s)');
      unawaited(flushOutbox());
    }
    if (restored) {
      unawaited(flushUploads());
    }
  }

  /// Waits for the in-flight turn to finish. False on timeout — the caller
  /// must leave the attempt alone (it may still complete).
  Future<bool> _waitForIdle() async {
    final stopAt = DateTime.now().add(const Duration(minutes: 10));
    while (_isLoading) {
      if (DateTime.now().isAfter(stopAt)) {
        AppLogger.warning('ChatComposer: flush idle-wait timed out; attempt left live');
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return true;
  }

  void stopGeneration() {
    if (!_isLoading) return;
    _generationCancelled = true;
    _aiSubscription?.cancel();
    _finalizeStream();
  }

  void _finishTurn() {
    _isLoading = false;
    _isStreaming = false;
    _activeAiLocalId = null;
    _notifyStateChanged();

    _onTurnCompleted?.call();

    // A completed turn may unblock queued messages (e.g. a busy-interrupted
    // flush, or quota that has since reset). Reentrancy-guarded inside.
    if (_outbox.pending.isNotEmpty && _connectionChecker.isInternetAvailable.value) {
      unawaited(flushOutbox());
    }
    // Same for uploads that failed mid-turn on a transient blip.
    if (_connectionChecker.isInternetAvailable.value) {
      unawaited(flushUploads());
    }
  }
}
