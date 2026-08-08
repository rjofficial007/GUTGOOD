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
  Widget build(BuildContext context) => Scaffold(
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
        _buildBody(context),
      ],
    ),
  );

  Widget _buildBody(BuildContext context) {
    final notifier = context.watch<InsightsNotifier>();
    final alerts = notifier.healthAlerts;

    if (alerts.isEmpty) return const _NoAlertsView();

    return _AlertList(alerts: alerts);
  }
}

class _NoAlertsView extends StatelessWidget {
  const _NoAlertsView();

  @override
  Widget build(BuildContext context) => const SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyStateWidget(icon: AppIcons.bell, title: 'No Alerts Yet', description: 'When we detect patterns or risks, they will appear here.'),
  );
}

class _AlertList extends StatelessWidget {
  const _AlertList({required this.alerts});
  final List<HealthAlert> alerts;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p20, vertical: AppSizes.p16),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final alert = alerts[index];
        return _AlertTile(alert: alert);
      }, childCount: alerts.length),
    ),
  );
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final HealthAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = context.appColorScheme.textPrimary;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p12),
      child: Container(
        padding: EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: context.appColorScheme.elevatedSurface,
          borderRadius: BorderRadius.circular(AppSizes.r20),
          border: Border.all(color: context.appColorScheme.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            // 1. Icon Container (Matches InsightHistoryTile w52x52)
            Container(
              width: AppSizes.w52,
              height: AppSizes.w52,
              decoration: BoxDecoration(color: context.appColorScheme.border.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(AppSizes.r12)),
              child: Icon(_getAlertIcon(alert.type), color: color, size: AppSizes.icon24),
            ),
            Gap.w16,
            // 2. Info (Title, Message, Meta)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          alert.title,
                          style: context.bodyBold.copyWith(fontSize: AppSizes.s15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!alert.isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: context.appColorScheme.error, shape: BoxShape.circle),
                        ),
                    ],
                  ),

                  Gap.h4,
                  Text(
                    '${alert.type.replaceAll('_', ' ').toUpperCase()} • ${DateFormat('MMM d, h:mm a').format(alert.time.toLocal())}',
                    style: context.caption.copyWith(color: context.appColorScheme.textMuted, fontWeight: FontWeight.bold, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}
