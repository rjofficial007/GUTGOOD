part of 'chat_composer_notifier.dart';

/// Regeneration and failed-message retry workflow.

extension ChatComposerRegeneration on ChatComposerNotifier {
  String _effectiveAiText({required String displayText, String? hiddenContext, required bool hasImages}) {
    if (displayText.isNotEmpty) {
      return hiddenContext != null && hiddenContext.isNotEmpty ? '$displayText\n\n$hiddenContext' : displayText;
    }
    return hiddenContext ?? 'Analyze this image for gut health.';
  }

  /// Returns [ChatSendError.offline] when refused for connectivity so the UI
  /// can say so — previously a retry tap while offline silently did nothing.
  Future<ChatSendError?> regenerateLastResponse() async {
    if (_isLoading || !_hasLastRequest) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

    if (_historyNotifier.messages.isNotEmpty && _historyNotifier.messages.first.role == 'ai') {
      final old = _historyNotifier.messages.first;
      await _historyNotifier.deleteMessage(old);
    }

    final placeholder = ChatMessage(localId: const Uuid().v4(), role: 'ai', text: '', isSwap: false, source: _lastSource, createdAt: DateTime.now());
    _historyNotifier.addOptimisticMessage(placeholder);
    _activeAiLocalId = placeholder.localId;

    _generationCancelled = false;
    _isLoading = true;
    _isStreaming = false;
    _notifyStateChanged();

    await _analyticsService.logEvent(name: 'message_regenerated', parameters: {'has_images': _lastSentImages.isNotEmpty});

    String? detectedMode;
    String? detectedIntent;

    if (_lastSentImages.isNotEmpty) {
      try {
        final classification = await _aiClassifierService.classifyImage(imageBytes: _lastSentImages.first, userText: _lastUserText, modeHint: _lastSource);
        detectedMode = classification.imageMode;
        detectedIntent = classification.intent;
      } catch (e) {
        AppLogger.warning('ChatComposer: Regeneration classification failed');
      }
    }

    final aiText = _effectiveAiText(displayText: _lastUserText ?? '', hiddenContext: _lastHiddenContext, hasImages: _lastSentImages.isNotEmpty);
    await _streamReply(
      userText: aiText,
      images: _lastSentImages.isEmpty ? null : _lastSentImages,
      imageUrl: _lastSentImageUrl,
      source: detectedMode ?? _lastSource,
      detectedIntent: detectedIntent,
      isRegenerate: true,
    );
    return null;
  }

  Future<ChatSendError?> retryMessage(ChatMessage failedMessage) async {
    if (_isLoading) return ChatSendError.busy;
    if (!failedMessage.sendFailed) return null;

    await _historyNotifier.deleteMessage(failedMessage);

    final images = failedMessage.localImages ?? const <Uint8List>[];
    for (final bytes in images) {
      await addAttachment(bytes, source: failedMessage.source ?? 'gallery');
    }

    return send(text: failedMessage.text, source: failedMessage.source);
  }
}
