import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/insight_theme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/chat/domain/repositories/chat_repository.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';
import 'package:gutgood/features/insights/presentation/pages/swap_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_feed/insight_ui_kit.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/swap_recommendation_firestore_service.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

/// Better Food Swaps — Ultra-Polished, fully dynamic & compact UI/UX matching mockup.
class BetterSwapsScreen extends StatefulWidget {
  const BetterSwapsScreen({super.key, required this.swap, this.insight});

  final FoodSwap swap;
  final AIInsight? insight;

  @override
  State<BetterSwapsScreen> createState() => _BetterSwapsScreenState();
}

class _BetterSwapsScreenState extends State<BetterSwapsScreen> {
  String _selectedCategory = 'All Swaps';
  bool _didRequestAlternatives = false;
  bool _isLoadingAlternatives = false;
  bool _alternativeRequestFailed = false;
  List<SwapAlternative> _generatedAlternatives = const [];

  AIInsight? _insightOf(BuildContext context) {
    try {
      return widget.insight ?? context.read<InsightsNotifier>().latestInsight;
    } on ProviderNotFoundException {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didRequestAlternatives) {
      _didRequestAlternatives = true;
      _isLoadingAlternatives = true;
      _loadAlternatives(_insightOf(context));
    }
  }

  Future<void> _loadAlternatives(AIInsight? insight) async {
    final sourceName = widget.swap.source.name.trim();
    try {
      final pattern = insight?.detectedPatterns.where((candidate) {
        final source = sourceName.toLowerCase();
        return candidate.trigger.toLowerCase().trim() == source ||
            candidate.involvedFoods.any(
              (food) => food.toLowerCase().trim() == source,
            );
      }).firstOrNull;
      UserProfile? profile;
      try {
        profile = await sl<AuthFirestoreService>().getUserMetadata();
      } catch (_) {
        // Recommendations can still use the source food and logged pattern.
      }
      final requestContext = <String, Object?>{
        'food': sourceName,
        if (pattern != null)
          'logged_observation': {
            'response': pattern.reaction,
            'observations': pattern.frequency,
            'evidence_tier': pattern.evidenceLabel,
            'description': pattern.description,
            if (pattern.involvedFoods.isNotEmpty)
              'foods_logged_together': pattern.involvedFoods.take(6).toList(),
          },
        if (profile?.goals.isNotEmpty == true) 'user_goals': profile!.goals,
        if (profile?.sensitivities.isNotEmpty == true)
          'user_sensitivities': profile!.sensitivities,
      };
      final swapCache = sl<SwapRecommendationFirestoreService>();
      final cached = await swapCache.getCachedSwaps(
        sourceFoodName: sourceName,
        requestContext: requestContext,
        promptVersion: AiVersions.swapPromptVersion,
      );
      final cachedAlternatives = _validAlternatives(cached ?? const [], sourceName);
      if (cachedAlternatives.isNotEmpty) {
        if (mounted) setState(() => _generatedAlternatives = cachedAlternatives);
        return;
      }

      final suppliedAlternatives = _validAlternatives(
        widget.swap.alternatives,
        sourceName,
      );
      if (suppliedAlternatives.isNotEmpty) {
        await swapCache.saveSwaps(
          sourceFoodName: sourceName,
          requestContext: requestContext,
          promptVersion: AiVersions.swapPromptVersion,
          alternatives: suppliedAlternatives,
        );
        if (mounted) {
          setState(() => _generatedAlternatives = suppliedAlternatives);
        }
        return;
      }

      final repository = sl<ChatRepository>();
      final response = StringBuffer();
      await for (final chunk in repository.sendMessageStream(
        systemInstruction: _swapRecommendationInstruction,
        history: const [],
        userText: ModelUtils.safeJsonEncode(requestContext),
        intent: 'meal_swaps',
        promptVersion: AiVersions.swapPromptVersion,
      )) {
        response.write(chunk);
      }
      if (repository.lastResponseTruncated) {
        throw const FormatException('The swap response was incomplete.');
      }
      final json = ModelUtils.extractJson(response.toString(), isArray: true);
      if (json == null) {
        throw const FormatException('The swap response was not valid JSON.');
      }
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        throw const FormatException('The swap response was not a list.');
      }

      final alternatives = _validAlternatives(
        decoded.whereType<Map>().map(
          (item) => SwapAlternative.fromMap(Map<String, dynamic>.from(item)),
        ),
        sourceName,
      );
      if (alternatives.isEmpty) {
        throw const FormatException('No suitable swaps were returned.');
      }
      await swapCache.saveSwaps(
        sourceFoodName: sourceName,
        requestContext: requestContext,
        promptVersion: AiVersions.swapPromptVersion,
        alternatives: alternatives,
      );
      if (mounted) setState(() => _generatedAlternatives = alternatives);
    } catch (error) {
      AppLogger.ai('Load better food swaps failed', error: error);
      if (mounted) setState(() => _alternativeRequestFailed = true);
    } finally {
      if (mounted) setState(() => _isLoadingAlternatives = false);
    }
  }

  List<SwapAlternative> _validAlternatives(
    Iterable<SwapAlternative> candidates,
    String sourceName,
  ) {
    final source = sourceName.trim().toLowerCase();
    final names = <String>{};
    return normalizeSwapCards(
      candidates.map((alternative) => ProductSwap.fromMap(alternative.toMap())).toList(),
      const [],
      sourceFoodName: sourceName,
    ).map((swap) => swap.toAlternative())
        .where((alternative) {
          final name = alternative.name.trim().toLowerCase();
          return name.isNotEmpty &&
              name != source &&
              alternative.reason?.trim().isNotEmpty == true &&
              names.add(name);
        })
        .take(4)
        .toList();
  }

  void _retryAlternatives(AIInsight? insight) {
    setState(() {
      _alternativeRequestFailed = false;
      _isLoadingAlternatives = true;
    });
    _loadAlternatives(insight);
  }

  @override
  Widget build(BuildContext context) {
    final insight = _insightOf(context);
    final foodName = widget.swap.source.name;
    final imageUrl = widget.swap.source.imageUrl;
    final alternatives = _generatedAlternatives.isNotEmpty
        ? _generatedAlternatives
        : _validAlternatives(widget.swap.alternatives, foodName);

    // Dynamic pattern matching
    final matchingPattern = insight?.detectedPatterns
        .where(
          (p) =>
              p.involvedFoods.any(
                (f) => f.toLowerCase().trim() == foodName.toLowerCase().trim(),
              ) ||
              p.trigger.toLowerCase().trim() == foodName.toLowerCase().trim(),
        )
        .firstOrNull;

    // Dynamic trigger matching
    final matchingTrigger = insight?.triggerFoods
        .where(
          (f) => f.name.toLowerCase().trim() == foodName.toLowerCase().trim(),
        )
        .firstOrNull;

    final hasPersonalEvidence =
        matchingPattern != null || matchingTrigger != null;
    final isPositiveObservation =
        matchingPattern?.impactDirection.toLowerCase() == 'positive';
    final heroSubtitle = matchingPattern?.reaction.isNotEmpty == true
        ? 'Linked to ${matchingPattern!.reaction.toLowerCase()} in your logs.'
        : (matchingTrigger?.effect.isNotEmpty == true
              ? matchingTrigger!.effect
              : 'No personal association has been established from your logs.');

    final heroTags = <String>[
      if (matchingPattern != null && matchingPattern.frequency > 0)
        '${matchingPattern.frequency}x Observed',
      if (matchingPattern?.reaction.isNotEmpty == true)
        matchingPattern!.reaction,
      if (matchingTrigger?.effect.isNotEmpty == true) matchingTrigger!.effect,
    ];

    // Dynamic Why affect you explanation
    final whyExplanation = (matchingPattern?.description.isNotEmpty == true)
        ? matchingPattern!.description
        : (matchingTrigger?.effect.isNotEmpty == true
              ? '$foodName (${matchingTrigger!.effect}) may place additional strain on your digestive system based on your meal logs.'
              : 'This is a general food alternative. Your logs do not yet show enough evidence to explain how the source food affects you.');

    final categoryLabels = <String, String>{};
    for (final alternative in alternatives) {
      final category = alternative.category.trim();
      if (category.isNotEmpty) {
        categoryLabels.putIfAbsent(category.toLowerCase(), () => category);
      }
    }
    final categories = <String>['All Swaps', ...categoryLabels.values];

    if (!categories.contains(_selectedCategory)) {
      _selectedCategory = 'All Swaps';
    }

    final filteredAlternatives = alternatives.where((alt) {
      if (_selectedCategory == 'All Swaps') return true;
      return alt.category.toLowerCase() == _selectedCategory.toLowerCase();
    }).toList();

    final scaffoldBg = context.appColorScheme.cardBackground;

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          GutSliverAppBar(
            title: 'BETTER FOOD SWAPS',
            centerTitle: true,
            showBrandingIcon: false,
            backgroundColor: scaffoldBg,
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 0.w, 16.w, 24.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. TRIGGER FOOD HERO CARD
                _buildTriggerHeroCard(
                  context,
                  foodName,
                  imageUrl,
                  heroSubtitle,
                  heroTags,
                  hasPersonalEvidence: hasPersonalEvidence,
                  isPositiveObservation: isPositiveObservation,
                ),
                Gap.h12,

                // 2. WHY THIS MAY AFFECT YOU CARD
                _buildWhyAffectYouCard(
                  context,
                  whyExplanation,
                  hasPersonalEvidence: hasPersonalEvidence,
                ),
                Gap.h12,

                // 3. CATEGORY FILTER PILLS (Removed the extra Gap.h12 here)
                if (categories.length > 1)
                  _buildCategoryFilters(context, categories),
                Gap.h12,
                // 4. ALTERNATIVES GRID (2 columns)
                if (filteredAlternatives.isNotEmpty)
                  _buildAlternativesGrid(
                    context,
                    filteredAlternatives,
                    foodName,
                  )
                else if (_isLoadingAlternatives)
                  _buildLoadingState(context)
                else
                  _buildEmptyState(
                    context,
                    onRetry: _alternativeRequestFailed
                        ? () => _retryAlternatives(insight)
                        : null,
                  ),

                Gap.h16,

                // 5. GUIDANCE BANNER
                _buildGuidanceBanner(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// 1. Trigger Food Hero Card
  Widget _buildTriggerHeroCard(
    BuildContext context,
    String foodName,
    String? imageUrl,
    String subtitle,
    List<String> tags, {
    required bool hasPersonalEvidence,
    required bool isPositiveObservation,
  }) => Container(
    height: 180.w,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20.w),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8.w,
          offset: Offset(0, 3.w),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      fit: StackFit.expand,
      children: [
        InsightUiKit.foodImage(
          foodName,
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: Container(color: const Color(0xFF1E293B)),
          errorWidget: Container(color: const Color(0xFF1E293B)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.88),
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(14.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.w,
                    ),
                    decoration: BoxDecoration(
                      color: hasPersonalEvidence
                          ? (isPositiveObservation
                                ? const Color(0xFF15803D)
                                : const Color(0xFFDC2626))
                          : const Color(0xFF475569),
                      borderRadius: BorderRadius.circular(100.w),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositiveObservation
                              ? LucideIcons.leaf
                              : LucideIcons.triangleAlert,
                          size: 9.w,
                          color: Colors.white,
                        ),
                        Gap.w4,
                        Text(
                          isPositiveObservation
                              ? 'SUPPORTIVE OBSERVATION'
                              : (hasPersonalEvidence
                                    ? 'OBSERVED IN YOUR LOGS'
                                    : 'GENERAL ALTERNATIVE'),
                          style: TextStyle(
                            fontFamily: InsightTheme.fontFamily,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    foodName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.15,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Gap.h2,
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: InsightTheme.fontFamily,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Gap.h8,
                  Wrap(
                    spacing: 5.w,
                    runSpacing: 4.w,
                    children: [
                      for (final tag in tags) _HeroTagPill(label: tag),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );

  /// 2. "Why this may affect you" Card
  Widget _buildWhyAffectYouCard(
    BuildContext context,
    String explanation, {
    required bool hasPersonalEvidence,
  }) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: theme.border, width: 1.w),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFD97706).withValues(alpha: 0.20)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.lightbulb,
              size: 16.w,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
            ),
          ),
          Gap.w10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasPersonalEvidence
                      ? 'What your logs show'
                      : 'About this alternative',
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.textPrimary,
                  ),
                ),
                Gap.h3,
                Text(
                  explanation,
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: theme.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Category Filter Pills (Matching exact Insights tab bar style)
  Widget _buildCategoryFilters(BuildContext context, List<String> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = context.insightTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0) Gap.w8,
            GestureDetector(
              onTap: () => setState(() => _selectedCategory = categories[i]),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.w),
                decoration: BoxDecoration(
                  color: categories[i] == _selectedCategory
                      ? (isDark ? Colors.white : const Color(0xFF171717))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(100.w),
                  border: Border.all(
                    color: categories[i] == _selectedCategory
                        ? (isDark ? Colors.white : const Color(0xFF171717))
                        : theme.border,
                    width: 1.w,
                  ),
                  boxShadow: categories[i] == _selectedCategory
                      ? [
                          BoxShadow(
                            color:
                                (isDark
                                        ? Colors.black
                                        : const Color(0xFF17171B))
                                    .withValues(alpha: 0.15),
                            blurRadius: 4.w,
                            offset: Offset(0, 2.w),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  categories[i],
                  style: TextStyle(
                    fontFamily: InsightTheme.fontFamily,
                    fontSize: 12.sp,
                    fontWeight: categories[i] == _selectedCategory
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: categories[i] == _selectedCategory
                        ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                        : theme.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 5. Alternatives Grid (2 columns)
  Widget _buildAlternativesGrid(
    BuildContext context,
    List<SwapAlternative> alternatives,
    String foodName,
  ) => GridView.builder(
    padding:
        EdgeInsets.zero, // Added padding zero to kill default GridView margins
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10.w,
      mainAxisSpacing: 10.w,
      childAspectRatio: 0.8, // Compact ratio eliminating extra whitespace
    ),
    itemCount: alternatives.length,
    itemBuilder: (context, index) {
      final alt = alternatives[index];
      return _SwapCardItem(alt: alt, sourceFoodName: foodName);
    },
  );

  Widget _buildLoadingState(BuildContext context) {
    final theme = context.insightTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.w,
              color: const Color(0xFF059669),
            ),
          ),
          Gap.h10,
          Text(
            'Finding food-matched options…',
            style: TextStyle(
              fontFamily: InsightTheme.fontFamily,
              fontSize: 12.sp,
              color: theme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {VoidCallback? onRetry}) {
    final theme = context.insightTheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        children: [
          Text(
            _alternativeRequestFailed
                ? 'Couldn’t load food-matched options right now.'
                : 'No suitable alternatives were returned for this food.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: InsightTheme.fontFamily,
              fontSize: 12.sp,
              color: theme.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            Gap.h10,
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuidanceBanner(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.card,
        borderRadius: BorderRadius.circular(16.w),
        border: Border.all(color: theme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 26.w,
            height: 26.w,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFD97706).withValues(alpha: 0.20)
                  : const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              LucideIcons.lightbulb,
              size: 13.w,
              color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
            ),
          ),
          Gap.w10,
          Expanded(
            child: Text(
              'Try one swap at a time to accurately observe how your digestion responds.',
              style: TextStyle(
                fontFamily: InsightTheme.fontFamily,
                fontSize: 10.sp,
                color: theme.textSecondary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _swapRecommendationInstruction =
      '''You suggest practical food alternatives for the exact source food or meal in the request. The logged observation is personal context only; it is an association, not proof that the food caused a response. Never claim to treat, prevent, or relieve symptoms or disease. Do not recommend eliminating foods or infer allergies. Match the source type and meal format: a full meal gets full-meal alternatives, a drink gets drinks, and a packaged product keeps the same product type. Use the user's logged goals and sensitivities when provided. Suggest up to four distinct, realistic alternatives; return fewer or an empty array if you cannot make suitable suggestions. Give a concise, specific comparison without unsupported nutrition facts or health claims. Never estimate calories, nutrients, brands, barcodes, or product ratings. Set imageUrl, barcode, nutriscore, and nutrition facts to null when unknown; use imageKeyword for a plain food description. Return valid JSON only as an array of objects with fields: name, replaces, reason, category, tag, imageKeyword, imageUrl, barcode, nutriscore, impactLevel, benefitTags, structuredBenefits, whyBetterOption, nutrition. nutrition must include calories, protein, totalFat, carbohydrates, fiber, sugars, saturatedFat, sodium, servingSize, and basis. Calories are a numeric kcal value, gram values include g, sodium includes mg, and servingSize/basis describe what the values apply to. Use null for every unknown value; never estimate. Return 1-3 distinct structuredBenefits when supported, each with title, description, and icon (leaf, dumbbell, arrow_down, or flame). These cards describe useful features of this specific alternative: preparation, texture, flavor, or an ingredient characteristic. They do not require a nutrient comparison. Use a short title and a specific one-sentence description; do not repeat numeric macros, serving sizes, or the whyBetterOption sentence. Populate benefitTags with the same titles. Use higher/lower/fewer claims only with verified source and alternative data on the same basis. Never infer fewer additives from missing ingredients or claim easier digestion, symptom relief, or sustained energy from a food name. If no features are supported, use [] for both arrays.''';
}

class _HeroTagPill extends StatelessWidget {
  const _HeroTagPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.w),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(100.w),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontFamily: InsightTheme.fontFamily,
        fontSize: 9.5.sp,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

class _BenefitData {
  const _BenefitData({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class _SwapCardItem extends StatelessWidget {
  const _SwapCardItem({required this.alt, required this.sourceFoodName});
  final SwapAlternative alt;
  final String sourceFoodName;

  IconData _parseIcon(String raw) {
    final lower = raw.toLowerCase().trim();
    if (lower.contains('dumbbell') ||
        lower.contains('protein') ||
        lower.contains('muscle')) {
      return LucideIcons.dumbbell;
    }
    if (lower.contains('sprout') ||
        lower.contains('fiber') ||
        lower.contains('motility')) {
      return LucideIcons.sprout;
    }
    if (lower.contains('flame') ||
        lower.contains('calor') ||
        lower.contains('burn')) {
      return LucideIcons.flame;
    }
    if (lower.contains('sun') ||
        lower.contains('light') ||
        lower.contains('energy')) {
      return LucideIcons.sun;
    }
    if (lower.contains('shield') ||
        lower.contains('prebiotic') ||
        lower.contains('microbiome')) {
      return LucideIcons.shield;
    }
    if (lower.contains('droplet') ||
        lower.contains('water') ||
        lower.contains('hydrat')) {
      return LucideIcons.droplet;
    }
    if (lower.contains('arrow') || lower.contains('down')) {
      return LucideIcons.arrowDown;
    }
    return LucideIcons.leaf;
  }

  List<_BenefitData> _deriveBenefits(SwapAlternative alt) {
    if (alt.benefits.isNotEmpty) {
      return [
        for (final b in alt.benefits.take(2))
          _BenefitData(label: b.title, icon: _parseIcon(b.icon)),
      ];
    }

    final benefits = <_BenefitData>[];
    final reasonLower = (alt.reason ?? '').toLowerCase();
    if (reasonLower.contains('protein')) {
      benefits.add(
        const _BenefitData(label: 'Higher protein', icon: LucideIcons.dumbbell),
      );
    }
    if (reasonLower.contains('fat') || reasonLower.contains('saturat')) {
      benefits.add(
        const _BenefitData(label: 'Lower in fat', icon: LucideIcons.leaf),
      );
    }
    if (reasonLower.contains('fiber') || reasonLower.contains('plant')) {
      benefits.add(
        const _BenefitData(label: 'High fiber', icon: LucideIcons.sprout),
      );
    }
    if (reasonLower.contains('calor') || reasonLower.contains('light')) {
      benefits.add(
        const _BenefitData(label: 'Lower calories', icon: LucideIcons.flame),
      );
    }
    if (reasonLower.contains('process') ||
        reasonLower.contains('whole') ||
        reasonLower.contains('natural')) {
      benefits.add(
        const _BenefitData(label: 'Less processed', icon: LucideIcons.sparkles),
      );
    }
    return benefits.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = alt.imageUrl;
    final benefits = _deriveBenefits(alt);

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SwapDetailScreen(
            alternative: alt,
            sourceFoodName: sourceFoodName,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: BorderRadius.circular(16.w),
          border: Border.all(color: theme.border, width: 1.w),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
              blurRadius: 4.w,
              offset: Offset(0, 2.w),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Image
            InsightUiKit.foodImage(
              alt.name,
              imageUrl: imageUrl,
              height: 90.w,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: Container(color: theme.cardSubtle),
              errorWidget: Container(
                color: isDark
                    ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                    : const Color(0xFFDCFCE7),
                child: Icon(
                  LucideIcons.utensils,
                  size: 22.w,
                  color: isDark
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFF15803D),
                ),
              ),
            ),

            // Content Area
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          alt.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InsightTheme.fontFamily,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w800,
                            color: theme.textPrimary,
                            height: 1.15,
                          ),
                        ),
                        Gap.h2,
                        // Description
                        Text(
                          alt.reason?.trim().isNotEmpty == true
                              ? alt.reason!
                              : 'No comparison details are available for this alternative yet.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: InsightTheme.fontFamily,
                            fontSize: 9.sp,
                            color: theme.textSecondary,
                            height: 1.2,
                          ),
                        ),
                        Gap.h4,
                        // Benefit pills row
                        Wrap(
                          spacing: 4.w,
                          runSpacing: 3.w,
                          children: [
                            for (final b in benefits)
                              _BenefitPill(label: b.label, icon: b.icon),
                          ],
                        ),
                      ],
                    ),

                    // Compact Pill Button (Matching Mockup Image 2)
                    SizedBox(
                      width: double.infinity,
                      child: Material(
                        color: isDark
                            ? const Color(0xFF059669)
                            : const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(100.w),
                        child: InkWell(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SwapDetailScreen(
                                alternative: alt,
                                sourceFoodName: sourceFoodName,
                              ),
                            ),
                          ),
                          borderRadius: BorderRadius.circular(100.w),
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 7.w),
                            child: Center(
                              child: Text(
                                '+ Try This Swap',
                                style: TextStyle(
                                  fontFamily: InsightTheme.fontFamily,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = context.insightTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.w),
      decoration: BoxDecoration(
        color: isDark ? theme.cardSubtle : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 8.w,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF15803D),
          ),
          Gap.w4,
          Text(
            label,
            style: TextStyle(
              fontFamily: InsightTheme.fontFamily,
              fontSize: 8.sp,
              fontWeight: FontWeight.w700,
              color: theme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
