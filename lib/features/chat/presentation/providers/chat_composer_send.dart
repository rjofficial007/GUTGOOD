part of 'chat_composer_notifier.dart';

/// Primary message-send workflow.

extension ChatComposerSend on ChatComposerNotifier {
  Future<ChatSendError?> send({String text = '', String? hiddenContext, String? source, String? providedUserMsgId}) async {
    if (_isLoading) return ChatSendError.busy;

    final displayText = text.trim();
    final sending = List<ChatAttachment>.of(_attachments);

    if (displayText.isEmpty && sending.isEmpty) return ChatSendError.empty;
    if (!_connectionChecker.isInternetAvailable.value) {
      // Text-only turns queue for auto-send on reconnect. Image turns stay
      // online-only: bytes never enter the prefs outbox, so the draft
      // (text + attachments) is kept for a manual retry instead.
      if (sending.isNotEmpty) return ChatSendError.offline;
      await _enqueueOffline(displayText, hiddenContext: hiddenContext, source: source, providedId: providedUserMsgId);
      return ChatSendError.queued;
    }

    _hasLastRequest = true;
    _lastUserText = displayText;
    _lastHiddenContext = hiddenContext;
    _lastSource = source;
    _lastSentImages = sending.map((a) => a.bytes).toList(growable: false);
    _lastSentImageUrl = null;

    _attachments.clear();
    _generationCancelled = false;

    final userMsg = ChatMessage(
      localId: providedUserMsgId ?? const Uuid().v4(),
      role: 'user',
      text: displayText,
      localImages: sending.isEmpty ? null : _lastSentImages,
      isSending: sending.isNotEmpty,
      isSwap: false,
      source: source ?? (sending.isNotEmpty ? sending.first.source : 'chat'),
      createdAt: DateTime.now(),
    );

    final aiPlaceholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: userMsg.source, createdAt: DateTime.now().add(const Duration(milliseconds: 1)));

    _historyNotifier
      ..addOptimisticMessage(userMsg)
      ..addOptimisticMessage(aiPlaceholder);
    _activeAiLocalId = aiPlaceholder.localId;

    _isLoading = true;
    _isStreaming = false;
    _notifyStateChanged();

    await _analyticsService.logEvent(name: 'message_sent', parameters: {'has_attachments': sending.isNotEmpty, 'text_length': displayText.length, 'source': userMsg.source ?? 'chat'});

    final aiText = _effectiveAiText(displayText: displayText, hiddenContext: hiddenContext, hasImages: sending.isNotEmpty);

    // 🚀 Latency Optimization: Start classification and message saving in parallel.
    // We also prepare the classification future early to avoid sequential blocking.
    final classificationFuture = sending.isNotEmpty
        ? _aiClassifierService.classifyImage(imageBytes: sending.first.bytes, userText: displayText, modeHint: sending.first.source)
        : (displayText.isNotEmpty
              ? _aiClassifierService
                    .classifyTextIntent(userText: displayText, historySummary: _historyNotifier.cachedSummary)
                    .then((intent) => AiClassificationResult(imageMode: 'UNKNOWN', intent: intent, confidence: 1.0))
              : Future.value(const AiClassificationResult(imageMode: 'UNKNOWN', intent: 'COMPLETE_ANALYSIS', confidence: 1.0)));

    String? detectedMode;
    String? detectedIntent;

    if (sending.isNotEmpty) {
      if (_auth.currentUser == null) {
        _historyNotifier
          ..replaceMessage(userMsg.localId, userMsg.copyWith(isSending: false, sendFailed: true))
          ..removeMessage(aiPlaceholder.localId);
        _finishTurn();
        return ChatSendError.uploadFailed;
      }

      // P1-3a: the Storage upload must not gate the AI turn. Classify now
      // (fast, shapes the prompt; defaults on failure), save the user message
      // immediately so the turn is durable, stream from in-memory bytes, and
      // hydrate Storage URLs as a background patch. A failed upload degrades
      // to local-only bytes instead of killing a turn the AI could complete.
      try {
        final classification = await classificationFuture;
        detectedMode = classification.imageMode;
        detectedIntent = classification.intent;
        AppLogger.ai('ChatComposer: AI classified image as $detectedMode with intent $detectedIntent');
      } catch (e) {
        AppLogger.warning('ChatComposer: image classification failed, continuing with defaults. Error: $e');
      }

      final saved = await _repository.saveMessage(userMsg);
      _historyNotifier.replaceMessage(userMsg.localId, saved);

      unawaited(_uploadAndHydrate(sending, userMsg.localId));
    } else {
      try {
        // Parallelize message saving and classification
        final results = await Future.wait([_repository.saveMessage(userMsg), classificationFuture]);

        final saved = results[0] as ChatMessage;
        _historyNotifier.replaceMessage(userMsg.localId, saved);

        final classification = results[1] as AiClassificationResult;
        detectedIntent = classification.intent;
        AppLogger.ai('ChatComposer: AI detected text intent as $detectedIntent');
      } catch (e) {
        AppLogger.warning('ChatComposer: text-turn setup failed, falling back to defaults. Error: $e');
      }
    }

    await _streamReply(
      userText: aiText,
      images: sending.isEmpty ? null : _lastSentImages,
      // Always null here now: the URL arrives via _uploadAndHydrate, which
      // patches the AI message best-effort when the upload wins the race.
      imageUrl: null,
      source: detectedMode ?? userMsg.source,
      detectedIntent: detectedIntent,
    );

    return null;
  }
}
