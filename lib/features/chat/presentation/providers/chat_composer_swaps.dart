part of 'chat_composer_notifier.dart';

/// Grounded see-more-swaps workflow.

extension ChatComposerSwaps on ChatComposerNotifier {
  /// Adds new alternatives to the existing AI message; no chat or scan record
  /// is created for a pagination request.
  Future<ChatSendError?> handleSeeMoreSwaps(ChatMessage message) async {
    if (_isLoading) return ChatSendError.busy;
    if (!_connectionChecker.isInternetAvailable.value) return ChatSendError.offline;

    final scan = message.scanData;
    final existing = message.swapData ?? const <ProductSwap>[];
    final existingNames = existing.map((swap) => swap.title.trim().toLowerCase()).where((name) => name.isNotEmpty).toSet();
    final existingBarcodes = existing.map((swap) => swap.barcode?.trim()).whereType<String>().where((barcode) => barcode.isNotEmpty).toSet();

    _isLoading = true;
    _loadingSwapsMessageId = message.localId;
    _notifyStateChanged();

    try {
      await _analyticsService.logEvent(name: 'see_more_swaps_clicked', parameters: {'message_id': message.localId});

      // Barcode alternatives are real product candidates. Remove choices
      // already displayed before asking the model to select new ones.
      List<ProductSwap>? groundedSwaps;
      final barcode = scan?.barcode;
      if (barcode != null && barcode.isNotEmpty) {
        try {
          final product = await _offService.getProduct(barcode);
          final category = product?.categoryTag;
          if (category != null && category.isNotEmpty) {
            final alternatives = await _offService.getBetterAlternatives(category, scan?.nutriscore ?? product?.nutriscore);
            final unseen = alternatives
                .map((product) => product.toSwap())
                .where((swap) => !existingNames.contains(swap.title.trim().toLowerCase()) && (swap.barcode == null || !existingBarcodes.contains(swap.barcode)))
                // ponytail: cap the catalog context at eight candidates; it
                // is enough to select four and keeps the request payload small.
                .take(8)
                .toList();
            // The model is restricted to this list when it is supplied. A
            // shorter list cannot satisfy the UI's all-or-four card contract,
            // so fall back to general food suggestions instead of failing.
            if (unseen.length >= kSwapCardCount) groundedSwaps = unseen;
          }
        } catch (e) {
          AppLogger.ai('Fetch alternatives failed', error: e);
        }
      }

      final foodItems = [...message.mealLogs.expand((meal) => meal.items), ...message.foodMentions];
      final foodName = scan?.productName ?? (foodItems.isNotEmpty ? foodItems.join(', ') : message.text.trim());
      final requestContext = <String, Object?>{
        'food': foodName,
        if (scan?.brand.isNotEmpty == true) 'brand': scan!.brand,
        if (scan?.category?.isNotEmpty == true) 'category': scan!.category!,
        'alreadyShown': existing.map((swap) => swap.title).toList(),
        if (groundedSwaps != null)
          'availableProducts': groundedSwaps
              .map(
                (swap) => {
                  'name': swap.title,
                  if (swap.barcode != null) 'barcode': swap.barcode,
                  if (swap.nutriscore != null) 'nutriscore': swap.nutriscore,
                  if (swap.imageUrl != null) 'imageUrl': swap.imageUrl,
                },
              )
              .toList(),
        if (_historyNotifier.userGoals.isNotEmpty) 'goals': _historyNotifier.userGoals,
        if (_historyNotifier.userSensitivities.isNotEmpty) 'sensitivities': _historyNotifier.userSensitivities,
      };

      final response = StringBuffer();
      await for (final chunk in _repository.sendMessageStream(
        systemInstruction:
            '''You recommend practical alternatives for the source food. Return ONLY a JSON array of exactly 4 NEW distinct objects, with no prose or wrapper object. Exclude every item in alreadyShown. Each object must contain: name, replaces, reason, category, tag, imageKeyword, imageUrl, barcode, nutriscore, impactLevel, benefitTags, structuredBenefits, whyBetterOption, nutrition. Set replaces to the exact scanned dish or product, or an identified food in a multi-item scan. Match whole-dish type: pizza→pizza; burger/fast food→complete burger, sandwich, filled wrap, or bowl. A missing nutrient never changes type: low-protein pizza gets a protein-topped pizza, not chicken/chickpeas alone. Never use a side, ingredient, or plain wrap as a full-meal swap; don't change tacos into noodles or a snack into a meal. For packaged food, keep the same product type. If the source is vague, use close variants, not random healthy foods. Give a specific reason and source comparison with a real tradeoff. Avoid generic health claims and unsupported weight-loss, calorie, symptom-relief, or disease claims. Return 1-3 distinct structuredBenefits when supported, each with title, description, and icon (leaf, dumbbell, arrow_down, or flame). These cards describe useful features of this specific alternative: preparation, texture, flavor, or an ingredient characteristic. They do not require a nutrient comparison. Use a short title and a specific one-sentence description; do not repeat numeric macros, serving sizes, or the whyBetterOption sentence. Populate benefitTags with the same titles. Use higher/lower/fewer claims only with verified source and alternative data on the same basis. Never infer fewer additives from missing ingredients or claim easier digestion, symptom relief, or sustained energy from a food name. If no features are supported, use [] for both arrays. Nutrition requires calories, protein, totalFat, carbohydrates, fiber, sugars, saturatedFat, sodium, servingSize, and basis. Calories are a numeric kcal value, gram values include g, and sodium includes mg. Unknown values are null. Never estimate. Copy facts only from availableProducts; generic alternatives have null imageUrl, barcode, and nutriscore. Respect goals and sensitivities. Return exactly four distinct alternatives.''',
        history: const [],
        userText: ModelUtils.safeJsonEncode(requestContext),
        intent: 'meal_swaps',
        promptVersion: AiVersions.chatPromptVersion,
      )) {
        response.write(chunk);
      }

      final json = ModelUtils.extractJson(response.toString(), isArray: true);
      if (json == null) throw const FormatException('Swap response did not contain a JSON array.');
      final decoded = jsonDecode(json);
      if (decoded is! List) throw const FormatException('Swap response was not an array.');

      final parsed = decoded
          .whereType<Map>()
          .map((item) => ProductSwap.fromMap(Map<String, dynamic>.from(item)))
          .where((swap) {
            final name = swap.title.trim().toLowerCase();
            final code = swap.barcode?.trim();
            return name.isNotEmpty && name != 'string' && swap.subtitle.trim().isNotEmpty && !existingNames.contains(name) && (code == null || code.isEmpty || !existingBarcodes.contains(code));
          })
          .take(kSwapCardCount)
          .toList();
      final newSwaps = normalizeSwapCards(parsed, groundedSwaps ?? const [], sourceFoodName: foodName);
      if (newSwaps.isEmpty) throw const FormatException('Swap response did not contain any usable new alternatives.');

      final currentIndex = _historyNotifier.messages.indexWhere((item) => item.localId == message.localId);
      if (currentIndex == -1 || _loadingSwapsMessageId != message.localId) return ChatSendError.failed;
      final currentMessage = _historyNotifier.messages[currentIndex];
      final combinedSwaps = [...(currentMessage.swapData ?? const <ProductSwap>[]), ...newSwaps];
      final sourceScan = currentMessage.scanData ?? currentMessage.analysisResult?.scan;
      final updatedScan = sourceScan?.copyWith(swaps: combinedSwaps);
      final updatedAnalysis = currentMessage.analysisResult?.copyWith(swaps: combinedSwaps, scan: updatedScan);
      final updatedMessage = currentMessage.copyWith(scanData: updatedScan, swapData: combinedSwaps, isSwap: true, analysisResult: updatedAnalysis);
      _historyNotifier.replaceMessage(message.localId, updatedMessage);

      // saveMessage uses the stable localId as the Firestore document ID, so
      // this updates the same chat record and cannot duplicate its scan.
      final savedMessage = await _repository.saveMessage(updatedMessage);
      _historyNotifier.replaceMessage(message.localId, savedMessage);
      final scanId = updatedScan?.scanId;
      if (scanId != null && scanId.isNotEmpty) {
        final scanUpdated = await _historyNotifier.appendScanSwaps(scanId: scanId, swaps: newSwaps);
        if (!scanUpdated) AppLogger.warning('See more swaps saved to chat, but scan history sync failed for $scanId');
      }
      return null;
    } catch (e) {
      AppLogger.ai('See more swaps failed', error: e);
      return ChatSendError.failed;
    } finally {
      _isLoading = false;
      _loadingSwapsMessageId = null;
      _notifyStateChanged();
    }
  }
}
