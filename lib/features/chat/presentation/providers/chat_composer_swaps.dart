part of 'chat_composer_notifier.dart';

/// Grounded see-more-swaps workflow.

extension ChatComposerSwaps on ChatComposerNotifier {
  /// Returns [ChatSendError.offline] when refused for connectivity (same
  /// silent-tap fix as [regenerateLastResponse]).
  Future<ChatSendError?> handleSeeMoreSwaps(String prompt, ScanResult? scan) async {
    if (_isLoading) return null;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

    final userMsg = ChatMessage(localId: const Uuid().v4(), role: 'user', text: '${AppStrings.moreSwapsPrompt}$prompt', isSwap: false, isHidden: true, source: 'chat', createdAt: DateTime.now());
    final aiPlaceholder = ChatMessage(
      localId: const Uuid().v4(),
      role: 'ai',
      text: AppStrings.findingSwaps,
      isSwap: false,
      source: 'chat',
      createdAt: DateTime.now().add(const Duration(milliseconds: 1)),
    );

    _historyNotifier
      ..addOptimisticMessage(userMsg)
      ..addOptimisticMessage(aiPlaceholder);
    _isLoading = true;
    _notifyStateChanged();

    await _analyticsService.logEvent(name: 'see_more_swaps_clicked', parameters: {'prompt': prompt});

    try {
      final savedMsg = await _repository.saveMessage(userMsg);
      _historyNotifier.replaceMessage(userMsg.localId, savedMsg);

      // P2-11: ground "see more" in real OFF alternatives. The OFF category
      // tag isn't stored on ScanResult, so resolve it via the cached product
      // fetch (barcode → categoryTag); the 30-min OFF memo makes this ~free
      // right after a scan. Any failure (or no barcode) degrades to the
      // previous LLM-only behavior.
      List<ProductSwap>? groundedSwaps;
      final barcode = scan?.barcode;
      if (barcode != null && barcode.isNotEmpty) {
        try {
          final product = await _offService.getProduct(barcode);
          final category = product?.categoryTag;
          if (category != null && category.isNotEmpty) {
            final alternatives = await _offService.getBetterAlternatives(category, scan?.nutriscore ?? product?.nutriscore);
            if (alternatives.isNotEmpty) {
              groundedSwaps = alternatives.take(4).map((p) => p.toSwap()).toList();
            }
          }
        } catch (e) {
          AppLogger.ai('Fetch alternatives failed', error: e);
        }
      }

      final stream = _repository.sendMessageStream(
        systemInstruction: Prompts.chatSystemInstruction(
          userGoals: _historyNotifier.userGoals,
          userSensitivities: _historyNotifier.userSensitivities,
          userLifestyle: _historyNotifier.userLifestyle,
          cyclePhase: _historyNotifier.cyclePhase,
          communicationStyle: _historyNotifier.commStyle,
          historySummary: _historyNotifier.cachedSummary,
          pinnedEntities: _pinnedEntities(),
          currentTime: DateTime.now().toIso8601String(),
          mode: 'swaps',
          intent: 'meal_swaps',
        ),
        history: _buildHistory(),
        userText: groundedSwaps != null ? ChatPromptContext.swapsGroundingFragment(userMsg.text, groundedSwaps) : userMsg.text,
        intent: 'meal_swaps',
        promptVersion: AiVersions.chatPromptVersion,
      );

      final aiLocalId = aiPlaceholder.localId;
      final fullTextBuffer = StringBuffer();
      final persistedTags = <String>{};

      await for (final chunk in stream) {
        fullTextBuffer.write(chunk);
        final result = _processChatTagUseCase(
          fullTextBuffer.toString(),
          userText: userMsg.text,
          source: 'chat',
          chatMessageId: aiLocalId,
          isFinal: false,
          promptVersion: AiVersions.chatPromptVersion,
          servedModel: null,
          fallbackSwaps: groundedSwaps ?? const [],
        );

        var finalToDisplay = result.text;
        if (finalToDisplay.isEmpty && result.swaps.isNotEmpty) {
          finalToDisplay = AppStrings.hereAreSomeBetterSwaps;
        }

        final currentAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
        _historyNotifier.replaceMessage(
          aiLocalId,
          currentAi.copyWith(
            text: finalToDisplay,
            scanData: result.scan,
            mealLogs: result.meal != null ? [result.meal!] : const [],
            symptomLogs: result.symptoms,
            swapData: result.swaps,
            isSwap: result.swaps.isNotEmpty,
            analysisResult: result,
            foodMentions: [if (result.meal != null) ...result.meal!.items, if (result.scan != null) result.scan!.productName].whereType<String>().toList(),
            symptomMentions: result.symptoms.map((e) => e.symptom).toList(),
          ),
        );
        _notifyStateChanged();
      }

      // J-4/P3-4: capture the echo flags NOW — the persist await below could
      // let a concurrent AI call's reset interleave before the stamping copyWith.
      final wasTruncated = _repository.lastResponseTruncated;
      final promptVersion = _repository.lastPromptVersion ?? AiVersions.chatPromptVersion;
      final servedModel = _repository.lastServedModel;

      // Atomic persistence for See More Swaps
      final finalResult = _processChatTagUseCase(
        fullTextBuffer.toString(),
        userText: userMsg.text,
        source: 'chat',
        chatMessageId: aiLocalId,
        isFinal: true,
        promptVersion: promptVersion,
        servedModel: servedModel,
        fallbackSwaps: groundedSwaps ?? const [],
      );
      final hydratedResult = await _persistAiResponseUseCase(finalResult, chatMessageId: aiLocalId, source: 'chat', persistedTagBlocks: persistedTags);

      final finalAi = _historyNotifier.messages.firstWhere((m) => m.localId == aiLocalId);
      final updatedAi = finalAi.copyWith(
        scanData: hydratedResult.scan,
        mealLogs: hydratedResult.meal != null ? [hydratedResult.meal!] : null,
        symptomLogs: hydratedResult.symptoms,
        swapData: hydratedResult.swaps,
        analysisResult: hydratedResult,
        wasTruncated: wasTruncated,
        promptVersion: promptVersion,
        model: servedModel,
      );
      _historyNotifier.replaceMessage(aiLocalId, updatedAi);

      final savedAi = await _repository.saveMessage(updatedAi);
      _historyNotifier.replaceMessage(aiLocalId, savedAi);
    } catch (e) {
      AppLogger.ai('See more swaps failed', error: e);
    } finally {
      _isLoading = false;
      _notifyStateChanged();
      unawaited(_historyNotifier.precomputeSummary());
    }
    return null;
  }
}
