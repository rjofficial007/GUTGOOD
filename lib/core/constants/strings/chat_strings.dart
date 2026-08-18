class ChatStrings {
  const ChatStrings._();

  static const String chatInitialGreeting = 'What’s good? 👋 Scan • Snap • Ask';
  static const String chatAuthMessage = 'Create a free account to save your results and start tracking your GutGood Score.';
  static const String imageUploadAnalysis = 'Image Upload Analysis 📷';

  // ---------------------------------------------------------------------
  // 🔴 DEPRECATED — DO NOT USE FOR PROMPT CONSTRUCTION.
  //
  // These five constants used to be sent to the AI as `hiddenContext`
  // directly from `ChatNotifier.handleImageAttachment`/`send()`, running
  // in PARALLEL with (and contradicting) the much more thorough,
  // mode-specific prompts in `mode_prompts.dart` — e.g. this file's
  // `restaurantMenuInstruction` said "[SCAN]/[SWAPS] MANDATORY" while
  // `ModePrompts.restaurantMenuInstruction` said structured tags are
  // "ABSOLUTELY STRICT...forbidden" for the same mode. That contradiction
  // was the direct cause of inconsistent mode-specific output.
  //
  // `ChatNotifier` now calls `Prompts.visionAnalysisSystemInstruction`
  // (which delegates to `ModePrompts`) as the actual SYSTEM INSTRUCTION for
  // any turn carrying an image + known mode, instead of appending one of
  // these strings as extra user-turn context on top of the generic chat
  // system prompt. These constants are kept only so any other lingering
  // call sites don't fail to compile; do not wire them into new code paths.
  // Prefer `ModePrompts`/`Prompts.visionAnalysisSystemInstruction` instead.
  // ---------------------------------------------------------------------
  @Deprecated('Use Prompts.visionAnalysisSystemInstruction(mode: "gallery"/"unknown") instead — see mode_prompts.dart / prompts.dart')
  static const String imageUploadInstruction = 'Look at the attached image (product, meal, or label) and analyze it for gut health. Provide structured [SCAN] and [MEAL] data as appropriate.';

  static const String restaurantMenuCheck = 'Restaurant Menu Check 🍽️';

  @Deprecated('Use Prompts.visionAnalysisSystemInstruction(mode: "menu") -> ModePrompts.restaurantMenuInstruction instead')
  static const String restaurantMenuInstruction =
      'Adopt the persona of a Restaurant Survival Guide. Analyze this menu. Suggest the top 3 gut-friendly picks and any helpful modifications (e.g. sauce on side). MANDATORY: Provide a [SCAN] block and a [SWAPS] block.';

  static const String mealPhotoAnalysis = 'Meal Photo Analysis 📸';

  @Deprecated('Use Prompts.visionAnalysisSystemInstruction(mode: "food") -> ModePrompts.mealSnapInstruction instead')
  static const String mealPhotoInstruction =
      'Adopt the persona of a Nutrition Coach. Analyze this meal for metabolic balance (Protein + Fiber + Fat). Provide a supportive rating. MANDATORY: You MUST provide BOTH a [MEAL] block AND a [SCAN] block. ALSO, if the user mentions how they feel, include a [SYMPTOM] block.';

  static const String ingredientLabelScan = 'Ingredient Label Scan 🔍';

  @Deprecated('Use Prompts.visionAnalysisSystemInstruction(mode: "label") -> ModePrompts.ingredientLabelInstruction instead')
  static const String ingredientLabelInstruction =
      'Adopt the persona of a Clinical Food Scientist. Perform a deep audit of additives, gums, and emulsifiers on this label. Flag anything triggering user sensitivities. MANDATORY: You MUST provide a [SCAN] block.';

  static const String visionScanPlaceholder = 'I scanned an item with AI.';

  @Deprecated('Use Prompts.visionAnalysisSystemInstruction(mode: "gallery") instead')
  static const String visionScanInstruction =
      'Look at the attached image and analyze it for gut health. Identify the product, meal, or label. Extract the product name, ingredients, and gut score. MANDATORY: You MUST provide a [SCAN] block. ALSO, if the user mentions how they feel, include a [SYMPTOM] block.';

  static const String restaurantSurvivalMode = '🍽️ Restaurant Survival Mode: Upload a menu photo to get gut-friendly picks.';
  static const String viewPremiumBenefits = 'View Premium Benefits';
  static const String findingSwaps = 'Finding more great swaps for you... ✨';
  static const String moreSwapsPrompt = 'Show me 3 more gut-friendly swaps for: ';
  static const String moreOptionsFound = 'Here are 3 more options you might like 👇';
  static const String symptomLogged = '✨ Logged symptom: ';
  static const String toYourInsights = ' to your insights';
  static const String mealItemsLearned = '🍽️ Meal items learned! Check your insights later.';
  static const String resultsFound = '\n\nHere is what I found ✨';
  static const String gutFriendlySwaps = '\n\nHere are some gut-friendly swaps you\'ll actually enjoy 👇';
  static const String errorConnectionFailed = '\n\n`[Error: Connection failed.]`';
  static const String thanksFeedback = 'Thanks for your feedback!';
  static const String chipBloated = 'Why do I feel bloated? 🤔';
  static const String chipBloatedPrompt = 'Why do I feel bloated after this?';
  static const String chipHealthy = 'Is this healthy? 🥗';
  static const String chipHealthyPrompt = 'Is this healthy?';
  static const String chipSwap = 'What to eat instead? 🔄';
  static const String chipSwapPrompt = 'What should I eat instead?';
  static const String chipRestaurant = 'Eating out tonight? 🍽️';
  static const String scanIngredientsMeal = 'Scan ingredients or meal';
  static const String sendMessage = 'Send message';
  static const String thinking = 'Thinking...';
  static const String askAnything = 'Ask anything...';
  static const String attachPhotos = 'Attach photos';
  static const String removeAttachment = 'Remove attachment';
  static const String stopGenerating = 'Stop generating';
  static const String maxAttachmentsMessage = 'You can attach up to 4 photos.';
  static const String copyMessage = 'Copy message';
  static const String regenerate = 'Regenerate';
  static const String retry = 'Retry';
  static const String connectionError = 'Connection dropped. Please try again.';
  static const String responseInterrupted = 'Response interrupted';
  static const String dailyLimitMessage = 'You\'ve hit today\'s free limit. Upgrade to GutGood+ for unlimited chats & scans.';
  static const String labelPhotoPrompt = 'Is this good for my gut?';
  static const String mealPhotoPrompt = 'What do you think of this meal?';
  static const String menuPhotoPrompt = 'What should I order here?';
  static const String galleryPhotoPrompt = 'What am I getting from this?';
  static const String heyImGutGood = 'Hey, I\'m GUTGOOD.';
  static const String gutgoodEmptyDescription = 'I\'m your gut health assistant. You can ask me anything about your food, log your meals, or scan products to see how they hit your body.';
  static const String helpful = 'Helpful';
  static const String notHelpful = 'Not helpful';
  static const String tellMeMore = 'Tell me more';
  static const String tellMeMorePrompt = 'Tell me more about this.';
  static const String gutGoodAnalysis = 'The GutGood Analysis';
  static const String comparingAnalysis = 'Comparing ';
  static const String withSwaps = ' with your recommended swaps.';
  static const String gotItThanks = 'Got it, thanks!';
  static const String whyBetter = 'Why are these better?';
  static const String viewFullReport = 'View Full Report';
  static const String gutImpact = 'GUT IMPACT';
  static const String labelHelpful = 'helpful';
  static const String labelNotHelpful = 'not_helpful';
  static const String labelTellMeMore = 'tell_more_more';
  static const String manuallyEnteredBarcode = 'I manually entered barcode for ';
  static const String messageCopied = 'Message copied to clipboard';
  static const String uploadFromGallery = 'Upload from gallery';
  static const String attachPhotosLabel = 'Attach photos';
  static const String keyBenefits = 'KEY BENEFITS';
  static const String gutProtection = 'Gut Protection';
  static const String gutProtectionDesc = 'Swaps are chosen to minimize inflammation and bloating.';
  static const String cleanIngredients = 'Clean Ingredients';
  static const String cleanIngredientsDesc = 'We prioritize options without the questionable ingredients found in your scan.';
  static const String bioAvailability = 'Bio-Availability';
  static const String bioAvailabilityDesc = 'These alternatives use whole-food sources that your body processes with less energy expenditure.';
  static const String contains = 'CONTAINS';
  static const String likelyImpact = 'LIKELY IMPACT';
  static const String swapThisInstead = 'SWAP THIS INSTEAD';
  static const String hereAreSomeBetterSwaps = 'Here are some better swaps for you:';

  static const String emptyStateTitle = 'Your food.\nYour body.\nYour patterns.';
  static const String emptyStateSubtitle = 'No judgment. No perfect diet.\nJust a better understanding of\nwhat works for you.';
  static const String emptyStateScanFood = 'Scan\na food';
  static const String emptyStateScanFoodDesc = 'Scan a product or ingredients';
  static const String emptyStateCheckIngredients = 'Check ingredients';
  static const String emptyStateCheckIngredientsDesc = "See what's really in your food";
  static const String emptyStateAskGutGood = 'Ask\nGutGood';
  static const String emptyStateAskGutGoodDesc = 'Ask anything about your food';
}
