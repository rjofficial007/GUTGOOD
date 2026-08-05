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

class NotificationArchiveScreen extends StatefulWidget {
  const NotificationArchiveScreen({super.key});

  @override
  State<NotificationArchiveScreen> createState() => _NotificationArchiveScreenState();
}

class _NotificationArchiveScreenState extends State<NotificationArchiveScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InsightsNotifier>().markAllAlertsAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final alerts = notifier.healthAlerts;

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: CustomScrollView(
        slivers: [
          GutSliverAppBar(
            title: 'Notification',
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
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSizes.p16),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appColorScheme.cardBackground,
        border: Border.all(color: context.appColorScheme.border),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(color: _getAlertColor(alert.type, context).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getAlertIcon(alert.type), color: _getAlertColor(alert.type, context), size: 14),
              ),
              Expanded(
                child: Text(alert.title, style: context.bodyBold.copyWith(fontSize: AppSizes.s15, height: 1.2)),
              ),
              if (!alert.isRead)
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: context.appColorScheme.error, shape: BoxShape.circle),
                ),
            ],
          ),
          Gap.h8,
          Text(alert.message, style: context.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.4)),
          Gap.h12,
          Text(DateFormat('MMM d, h:mm a').format(alert.time.toLocal()), style: context.caption.copyWith(fontSize: 10, color: context.appColorScheme.textMuted)),
        ],
      ),
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
