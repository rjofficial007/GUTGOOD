import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/date_formatter.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/insights/presentation/widgets/insight_dashboard_view.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:provider/provider.dart';

class InsightDetailScreen extends StatelessWidget {
  const InsightDetailScreen({super.key, required this.insight});
  final AIInsight insight;

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormatter.formatDate(insight.updatedAt);
    final profile = context.watch<ProfileNotifier>();
    final streak = profile.profile?.streak ?? 0;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(title: '${AppStrings.reportDate}${dateStr.toUpperCase()}', showBrandingIcon: false),
          InsightDashboardSliver(data: insight, streak: streak, isHistorical: true),
        ],
      ),
    );
  }
}
