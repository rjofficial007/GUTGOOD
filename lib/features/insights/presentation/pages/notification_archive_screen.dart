import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationArchiveScreen extends StatelessWidget {
  const NotificationArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final alerts = notifier.healthAlerts;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(
            title: 'Health Archive',
            leading: IconButton(
              icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
              onPressed: () => context.pop(),
            ),
          ),
          if (alerts.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyStateWidget(icon: AppIcons.bell, title: 'No Alerts Yet', description: 'When we detect patterns or risks, they will appear here.'),
            )
          else
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final alert = alerts[index];
                  return _AlertTile(alert: alert);
                }, childCount: alerts.length),
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final HealthAlert alert;

  @override
  Widget build(BuildContext context) => Container(
      margin: EdgeInsets.only(bottom: AppSizes.p12),
      padding: EdgeInsets.all(AppSizes.p16),
      decoration: BoxDecoration(
        color: context.appColorScheme.elevatedSurface,
        borderRadius: BorderRadius.circular(AppSizes.r16),
        border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSizes.p8),
                decoration: BoxDecoration(color: _getAlertColor(alert.type, context).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getAlertIcon(alert.type), color: _getAlertColor(alert.type, context), size: 16),
              ),
              Gap.w12,
              Expanded(
                child: Text(alert.title, style: context.bodyBold.copyWith(fontSize: AppSizes.s15)),
              ),
              Text(DateFormat('MMM d').format(alert.time), style: context.caption.copyWith(color: context.appColorScheme.textMuted)),
            ],
          ),
          Gap.h12,
          Text(alert.message, style: context.bodySm.copyWith(color: context.appColorScheme.textSecondary, height: 1.4)),
        ],
      ),
    );

  IconData _getAlertIcon(String type) {
    switch (type) {
      case 'processed_food':
        return AppIcons.alertTriangle;
      case 'insight_ready':
        return AppIcons.sparkles;
      case 'streak_saver':
        return AppIcons.flame;
      default:
        return AppIcons.bell;
    }
  }

  Color _getAlertColor(String type, BuildContext context) {
    switch (type) {
      case 'processed_food':
        return context.appColorScheme.error;
      case 'insight_ready':
        return context.appColorScheme.success;
      case 'streak_saver':
        return context.appColorScheme.warning;
      default:
        return context.appColorScheme.textPrimary;
    }
  }
}
