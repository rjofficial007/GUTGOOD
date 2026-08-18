import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/widgets/history_hub_sections.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> {
  List<HistoricalScan> _scans = [];
  List<MealLog> _meals = [];
  List<SymptomLog> _symptoms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    sl<AppStateService>().chatUpdated.addListener(_loadData);
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_history_hub'));
  }

  @override
  void dispose() {
    sl<AppStateService>().chatUpdated.removeListener(_loadData);
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = sl<HistoryRepository>();
    final results = await Future.wait([repo.getScanHistory(limit: 10), repo.getRecentMealLogs(limit: 10), repo.getRecentSymptomLogs(limit: 10)]);

    final scans = (results[0] as List<ScanResult>).map((s) => HistoricalScan(data: s, time: s.time ?? DateTime.now(), userImageUrl: s.userImageUrl)).toList();
    final meals = results[1] as List<MealLog>;
    final symptoms = results[2] as List<SymptomLog>;

    if (mounted) {
      setState(() {
        _scans = scans;
        _meals = meals;
        _symptoms = symptoms;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        const GutSliverAppBar(title: AppStrings.history),
        if (_isLoading) const _HistoryHubLoading() else _HistoryHubBody(scans: _scans, meals: _meals, symptoms: _symptoms),
      ],
    ),
  );
}

class _HistoryHubLoading extends StatelessWidget {
  const _HistoryHubLoading();

  @override
  Widget build(BuildContext context) => SliverFillRemaining(
    child: Center(child: CircularProgressIndicator(color: context.appColorScheme.textPrimary)),
  );
}

class _HistoryHubBody extends StatelessWidget {
  const _HistoryHubBody({required this.scans, required this.meals, required this.symptoms});
  final List<HistoricalScan> scans;
  final List<MealLog> meals;
  final List<SymptomLog> symptoms;

  @override
  Widget build(BuildContext context) => SliverPadding(
    padding: EdgeInsets.all(AppSizes.p20),
    sliver: SliverList(
      delegate: SliverChildListDelegate([
        AIHubSection(scans: scans, onViewAll: () => context.push(AppRoutes.allScans)),
        Gap.h24,
        MealHubSection(meals: meals),
        Gap.h24,
        SymptomHubSection(symptoms: symptoms),
        Gap.h40,
      ]),
    ),
  );
}
