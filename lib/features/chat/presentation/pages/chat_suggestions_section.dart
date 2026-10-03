part of 'chat_screen.dart';

/// Chat suggestion presentation component.

class _SuggestionChipsSection extends StatelessWidget {
  const _SuggestionChipsSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Selector<ChatHistoryNotifier, int>(
    selector: (_, n) => n.messages.length,
    builder: (context, count, _) {
      final suggestions = [
        AppStrings.suggestRateMeal,
        AppStrings.suggestBetterSwap,
        AppStrings.suggestBloatCheck,
        AppStrings.suggestIsThisHealthy,
        AppStrings.suggestMealPlan,
        AppStrings.suggestExplainIngredients,
        AppStrings.menuPhotoPrompt,
      ];

      return Container(
        height: 38,
        margin: EdgeInsets.only(bottom: AppSizes.p12),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
          itemCount: suggestions.length,
          itemBuilder: (context, i) => ChatSuggestionChip(
            label: suggestions[i],
            onTap: () {
              HapticHelper.light();

              controller.text = suggestions[i];

              controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));
            },
          ),
        ),
      );
    },
  );
}

// =============================================================================
// APP BAR
// =============================================================================

