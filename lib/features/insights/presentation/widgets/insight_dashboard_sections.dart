import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';

class ModernSmartAlert extends StatelessWidget {
  const ModernSmartAlert({super.key, required this.insight});
  final InsightSummary insight;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => context.push(AppRoutes.smartInsightDetail, extra: insight),
    child: ModernInsightCard(
      title: insight.title,
      icon: AppIcons.salad,
      backgroundColor: context.appColorScheme.cardBackground,
      titleColor: context.appColorScheme.textPrimary,
      iconColor: context.appColorScheme.textPrimary,
      padding: EdgeInsets.fromLTRB(AppSizes.p20, 0, AppSizes.p20, AppSizes.p20),
      footer: Text(
        '${insight.type.toUpperCase()}${AppStrings.insightLabelSuffix}  ➜',
        textAlign: TextAlign.center,
        style: context.captionBold.copyWith(color: context.appColorScheme.cardBackground),
      ),
      footerColor: context.appColorScheme.textPrimary,
      child: Text(
        insight.description,
        style: context.label.copyWith(color: context.appColorScheme.textPrimary, height: 1.4, fontWeight: FontWeight.w500),
        softWrap: true,
        maxLines: null,
      ),
    ),
  );
}
