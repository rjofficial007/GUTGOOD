part of 'chat_screen.dart';

/// Chat jump-to-latest presentation component.

class _JumpToLatestButton extends StatelessWidget {
  const _JumpToLatestButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appColorScheme;

    return Semantics(
      button: true,
      label: AppStrings.jumpToLatest,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colorScheme.textPrimary, borderRadius: BorderRadius.circular(AppSizes.r14)),
          child: Icon(AppIcons.arrowDown, size: 20, color: colorScheme.cardBackground, semanticLabel: null),
        ),
      ),
    );
  }
}
