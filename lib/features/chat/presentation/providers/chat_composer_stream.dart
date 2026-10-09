part of 'chat_composer_notifier.dart';

/// Streaming, tag processing, and response persistence workflow.

extension ChatComposerStream on ChatComposerNotifier {
  String? _displayImageForScan(ScanResult? scan, String? fallback) {
    if (scan == null) return fallback;
    return scan.isBarcodeScan ? scan.displayImageUrl : scan.displayImageUrl ?? fallback;
  }

  Future<void> _streamReply({required String userText, List<Uint8List>? images, String? imageUrl, String? source, String? detectedIntent, bool isRegenerate = false}) async {
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }

    _chunkBuffer = '';
    _fullAiText = '';
    _persistedTags.clear();
    _persistTagsForActiveTurn = !isRegenerate;

    // 🚀 PRD §10: Unified AI-driven routing.
    final intent = detectedIntent ?? source ?? 'full_analysis';

    AppLogger.ai('Final intent for prompt: "$intent" (detected: "$detectedIntent", source: "$source")');

    await _aiSubscription?.cancel();

    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(const Duration(milliseconds: 60), (_) {
      try {
        _flushChunkBuffer(imageUrl: imageUrl, source: source);
      } catch (e, st) {
        _flushTimer?.cancel();
        AppLogger.ai('Partial response processing failed; waiting for complete response', error: e, stackTrace: st);
      }
    });

    try {
      final stream = _sendMessageStreamUseCase(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _historyNotifier.userGoals,
          userSensitivities: _historyNotifier.userSensitivities,
          userLifestyle: _historyNotifier.userLifestyle,
          cyclePhase: _historyNotifier.cyclePhase,
          communicationStyle: _historyNotifier.commStyle,
          historySummary: _historyNotifier.cachedSummary,
          pinnedEntities: _pinnedEntities(),
          currentTime: DateTime.now().toIso8601String(),
          mode: source,
          intent: intent,
        ),
        history: _buildHistory(),
        userText: userText,
        images: images,
        intent: intent,
        promptVersion: AiVersions.chatPromptVersion,
      );

      var hapticTriggered = false;

      _aiSubscription = stream.listen(
        (chunk) {
          if (_generationCancelled) return;
          if (!hapticTriggered && chunk.isNotEmpty) {
            HapticHelper.medium();
            hapticTriggered = true;
          }
          if (chunk.isNotEmpty && !_isStreaming) {
            _isStreaming = true;
          }
          _chunkBuffer += chunk;
        },
        onError: (e) {
          AppLogger.ai('AI stream error', error: e);
          _handleStreamError(e, aiLocalId);
        },
        onDone: () {
          if (_generationCancelled) return;
          _finalizeStream();
        },
        cancelOnError: false,
      );
    } catch (e, st) {
      AppLogger.ai('Stream setup failed', error: e, stackTrace: st);
      await _handleStreamError(e, aiLocalId);
    }
  }

  void _flushChunkBuffer({String? imageUrl, String? source}) {
    if (_chunkBuffer.isEmpty) return;
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _chunkBuffer = '';
      return;
    }

    _fullAiText += _chunkBuffer;
    _chunkBuffer = '';

    final userText = _findUserTextForAiMessage(aiLocalId);
    final resolvedImageUrl = imageUrl ?? _findUserImageUrlForAiMessage(aiLocalId);
    final result = _processChatTagUseCase(
      _fullAiText,
      userText: userText,
      imageUrl: resolvedImageUrl,
      source: source,
      chatMessageId: aiLocalId,
      isFinal: false,
      promptVersion: AiVersions.chatPromptVersion,
      servedModel: null,
    );

    var finalToDisplay = ChatSafetyGuardrails.apply(result.text);
    if (finalToDisplay.isEmpty && (result.scan != null || result.swaps.isNotEmpty)) {
      finalToDisplay = AppStrings.resultsFound;
    }

    final currentMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
    final displayImageUrl = _displayImageForScan(result.scan, resolvedImageUrl);
    final updatedMsg = currentMsg.copyWith(
      text: finalToDisplay,
      scanData: result.scan,
      imageUrl: displayImageUrl,
      imageUrls: displayImageUrl != null ? [displayImageUrl] : (result.scan?.isBarcodeScan == true ? const [] : null),
      clearImageUrl: displayImageUrl == null && result.scan?.isBarcodeScan == true,
      mealLogs: result.scan == null && result.meal != null ? [result.meal!] : const [],
      symptomLogs: result.symptoms,
      swapData: result.swaps,
      isSwap: result.swaps.isNotEmpty,
      analysisResult: result,
      foodMentions: [if (result.scan == null && result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
      symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
    );

    _historyNotifier.replaceMessage(aiLocalId, updatedMsg);

    // 🟢 UI PERSISTENCE: Periodically persist the MESSAGE during streaming.
    // Domain events (meals/symptoms) are now ATOMIC and only persist once
    // at the end in _finalizeStream to prevent partial/corrupt data.
    final now = DateTime.now();
    if (_lastPersistTime == null || now.difference(_lastPersistTime!).inSeconds >= 3) {
      _lastPersistTime = now;
      unawaited(_persistAiMessage(aiLocalId));
    }

    _notifyStateChanged();
  }

  Future<void> _handleStreamError(Object error, String aiLocalId) async {
    _flushTimer?.cancel();
    try {
      final currentMsg = _historyNotifier.messages.firstWhere(
        (m) => m.localId == aiLocalId,
        orElse: () => ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()),
      );
      if (currentMsg.localId.isEmpty) {
        _finishTurn();
        return;
      }

      if (_chunkBuffer.isNotEmpty || _fullAiText.isNotEmpty) {
        _fullAiText += _chunkBuffer;
        _chunkBuffer = '';
        final userText = _findUserTextForAiMessage(aiLocalId);
        final resolvedImageUrl = currentMsg.imageUrl ?? _findUserImageUrlForAiMessage(aiLocalId);
        final result = _processChatTagUseCase(
          _fullAiText,
          userText: userText,
          imageUrl: resolvedImageUrl,
          source: currentMsg.source,
          chatMessageId: aiLocalId,
          isFinal: true,
          promptVersion: AiVersions.chatPromptVersion,
          servedModel: null,
        );
        final errorImageUrl = _displayImageForScan(result.scan, resolvedImageUrl);
        final finalMsg = currentMsg.copyWith(
          text: ChatSafetyGuardrails.apply(result.text),
          scanData: result.scan,
          imageUrl: errorImageUrl,
          imageUrls: errorImageUrl != null ? [errorImageUrl] : (result.scan?.isBarcodeScan == true ? const [] : null),
          clearImageUrl: errorImageUrl == null && result.scan?.isBarcodeScan == true,
          mealLogs: result.scan == null && result.meal != null ? [result.meal!] : const [],
          symptomLogs: result.symptoms,
          swapData: result.swaps,
          isSwap: result.swaps.isNotEmpty,
          analysisResult: result,
          foodMentions: [if (result.scan == null && result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
          symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
        );
        _historyNotifier.replaceMessage(aiLocalId, finalMsg);

        // Persist any partial but valid results if we at least got the tags
        if (_persistTagsForActiveTurn) {
          final hydratedResult = await _persistAiResponseUseCase(result, chatMessageId: aiLocalId, imageUrl: resolvedImageUrl, source: currentMsg.source, persistedTagBlocks: _persistedTags);
          final uploadedImageUrl = _findUserImageUrlForAiMessage(aiLocalId) ?? resolvedImageUrl;
          final persistedScan = uploadedImageUrl != null && hydratedResult.scan != null ? hydratedResult.scan!.copyWith(userImageUrl: uploadedImageUrl) : hydratedResult.scan;
          if (uploadedImageUrl != null && persistedScan?.scanId?.isNotEmpty == true) {
            await _historyNotifier.patchScanUserImageUrl(scanId: persistedScan!.scanId!, imageUrl: uploadedImageUrl);
          }
          final persistedImageUrl = _displayImageForScan(persistedScan, uploadedImageUrl);
          final updatedMsgWithIds = finalMsg.copyWith(
            scanData: persistedScan,
            imageUrl: persistedImageUrl,
            imageUrls: persistedImageUrl != null ? [persistedImageUrl] : (persistedScan?.isBarcodeScan == true ? const [] : null),
            clearImageUrl: persistedImageUrl == null && persistedScan?.isBarcodeScan == true,
            mealLogs: hydratedResult.meal == null ? const [] : [hydratedResult.meal!],
            symptomLogs: hydratedResult.symptoms,
          );
          _historyNotifier.replaceMessage(aiLocalId, updatedMsgWithIds);
        }
      }

      final kind = error is AiQuotaExceededException ? ChatErrorKind.quota : ChatErrorKind.connection;

      final updatedMsg = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
      if (updatedMsg.text.isNotEmpty && kind != ChatErrorKind.quota) {
        await _persistAiMessage(aiLocalId, errorKind: kind);
        _finishTurn();
        await _historyNotifier.precomputeSummary();
        return;
      }

      _historyNotifier.replaceMessage(aiLocalId, updatedMsg.copyWith(text: '', errorKind: kind));
      _finishTurn();
    } catch (e, st) {
      AppLogger.ai('Stream error recovery failed', error: e, stackTrace: st);
      for (final message in _historyNotifier.messages.where((m) => m.localId == aiLocalId)) {
        _historyNotifier.replaceMessage(aiLocalId, message.copyWith(errorKind: ChatErrorKind.connection));
        break;
      }
    } finally {
      if (_activeAiLocalId == aiLocalId) _finishTurn();
    }
  }

  Future<void> _finalizeStream() async {
    _flushTimer?.cancel();
    final aiLocalId = _activeAiLocalId;
    if (aiLocalId == null) {
      _finishTurn();
      return;
    }
    try {
      final currentMsg = _historyNotifier.messages.firstWhere(
        (m) => m.localId == aiLocalId,
        orElse: () => ChatMessage(localId: '', role: '', text: '', createdAt: DateTime.now()),
      );
      if (currentMsg.localId.isEmpty) {
        _finishTurn();
        return;
      }

      _fullAiText += _chunkBuffer;
      _chunkBuffer = '';
      final userText = _findUserTextForAiMessage(aiLocalId);
      final resolvedImageUrl = currentMsg.imageUrl ?? _findUserImageUrlForAiMessage(aiLocalId);
      final result = _processChatTagUseCase(
        _fullAiText,
        userText: userText,
        imageUrl: resolvedImageUrl,
        source: currentMsg.source,
        chatMessageId: aiLocalId,
        isFinal: true,
        promptVersion: _repository.lastPromptVersion ?? AiVersions.chatPromptVersion,
        servedModel: _repository.lastServedModel,
      );

      final displayImageUrl = _displayImageForScan(result.scan, resolvedImageUrl);
      final finalMsg = currentMsg.copyWith(
        text: ChatSafetyGuardrails.apply(result.text),
        scanData: result.scan,
        imageUrl: displayImageUrl,
        imageUrls: displayImageUrl != null ? [displayImageUrl] : (result.scan?.isBarcodeScan == true ? const [] : null),
        clearImageUrl: displayImageUrl == null && result.scan?.isBarcodeScan == true,
        mealLogs: result.scan == null && result.meal != null ? [result.meal!] : const [],
        symptomLogs: result.symptoms,
        swapData: result.swaps,
        isSwap: result.swaps.isNotEmpty,
        analysisResult: result,
        foodMentions: [if (result.scan == null && result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
        symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
        wasTruncated: _repository.lastResponseTruncated,
        promptVersion: _repository.lastPromptVersion ?? AiVersions.chatPromptVersion,
        model: _repository.lastServedModel,
      );
      _historyNotifier.replaceMessage(aiLocalId, finalMsg);

      if (finalMsg.text.isEmpty && finalMsg.scanData == null) {
        _historyNotifier.replaceMessage(aiLocalId, finalMsg.copyWith(errorKind: _generationCancelled ? ChatErrorKind.none : ChatErrorKind.connection));
        if (_generationCancelled) _historyNotifier.removeMessage(aiLocalId);
        _finishTurn();
        return;
      }

      // 🟢 ATOMIC PERSISTENCE: Now that the AI turn is finished and validated,
      // persist all domain logs (meals, symptoms, scans) to history.
      var finalToPersist = finalMsg;
      if (_persistTagsForActiveTurn && !_generationCancelled) {
        final latestImageUrl = _findUserImageUrlForAiMessage(aiLocalId) ?? resolvedImageUrl;
        final hydratedResult = await _persistAiResponseUseCase(result, chatMessageId: aiLocalId, imageUrl: latestImageUrl, source: currentMsg.source, persistedTagBlocks: _persistedTags);
        final uploadedImageUrl = _findUserImageUrlForAiMessage(aiLocalId) ?? latestImageUrl;
        final persistedScan = uploadedImageUrl != null && hydratedResult.scan != null ? hydratedResult.scan!.copyWith(userImageUrl: uploadedImageUrl) : hydratedResult.scan;
        if (uploadedImageUrl != null && persistedScan?.scanId?.isNotEmpty == true) {
          await _historyNotifier.patchScanUserImageUrl(scanId: persistedScan!.scanId!, imageUrl: uploadedImageUrl);
        }
        final persistedImageUrl = _displayImageForScan(persistedScan, uploadedImageUrl);

        // Update final message with IDs (firestoreId) so they can be saved as references in chat_history
        finalToPersist = finalMsg.copyWith(
          scanData: persistedScan,
          imageUrl: persistedImageUrl,
          imageUrls: persistedImageUrl != null ? [persistedImageUrl] : (persistedScan?.isBarcodeScan == true ? const [] : null),
          clearImageUrl: persistedImageUrl == null && persistedScan?.isBarcodeScan == true,
          mealLogs: hydratedResult.meal == null ? const [] : [hydratedResult.meal!],
          symptomLogs: hydratedResult.symptoms,
          swapData: hydratedResult.swaps,
          analysisResult: hydratedResult,
        );
        _historyNotifier.replaceMessage(aiLocalId, finalToPersist);
      }

      await _persistAiMessage(aiLocalId);
      _finishTurn();
      await _historyNotifier.precomputeSummary();
    } catch (e, st) {
      AppLogger.ai('Final response processing failed', error: e, stackTrace: st);
      for (final message in _historyNotifier.messages.where((m) => m.localId == aiLocalId)) {
        _historyNotifier.replaceMessage(aiLocalId, message.copyWith(errorKind: ChatErrorKind.connection));
        break;
      }
    } finally {
      if (_activeAiLocalId == aiLocalId) _finishTurn();
    }
  }

  Future<void> _persistAiMessage(String localId, {ChatErrorKind errorKind = ChatErrorKind.none}) async {
    try {
      final msg = _historyNotifier.messages.firstWhere((m) => m.localId == localId);
      final saved = await _repository.saveMessage(msg.copyWith(errorKind: errorKind));
      _historyNotifier.replaceMessage(localId, saved.copyWith(errorKind: errorKind));
    } catch (e) {
      AppLogger.ai('Saving AI response failed', error: e);
    }
  }
}
