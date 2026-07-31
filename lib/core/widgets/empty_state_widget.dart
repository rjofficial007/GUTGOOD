import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/responsive.dart';

/// A branded full-screen or section-level empty state indicator.
/// 
/// Used to inform the user when a list or view has no data, 
/// providing a relevant icon and encouraging next steps.
class EmptyStateWidget extends StatelessWidget {
  /// Large icon to represent the empty category (e.g., [AppIcons.history]).
  final IconData icon;
  
  /// Primary heading for the empty state.
  final String title;
  
  /// Descriptive body text explaining why the view is empty.
  final String description;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p40, vertical: AppSizes.p64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(AppSizes.p24),
              decoration: BoxDecoration(
                color: context.appColorScheme.elevatedSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48.0.w, color: context.appColorScheme.textMuted),
            ),
            Gap.h24,
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.headingSm.copyWith(fontWeight: FontWeight.w800),
            ),
            Gap.h12,
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.body.copyWith(
                color: context.appColorScheme.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
