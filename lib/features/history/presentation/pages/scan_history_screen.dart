import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/historical_scan.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/widgets/history_hub_sections.dart';
import 'package:provider/provider.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<HistoryNotifier>();

    return Scaffold(
      backgroundColor: context.appColorScheme.cardBackground,
      body: RefreshIndicator(
        onRefresh: notifier.refreshAll,
        color: context.appColorScheme.textPrimary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const GutSliverAppBar(title: AppStrings.history),
            if (notifier.scansLoading && notifier.mealsLoading && notifier.symptomsLoading)
              const _HistoryHubLoading()
            else
              _HistoryHubBody(
                scans: notifier.scans.map((s) => HistoricalScan(data: s, time: s.time ?? DateTime.now(), userImageUrl: s.userImageUrl)).toList(),
                meals: notifier.meals,
                symptoms: notifier.symptoms,
              ),
          ],
        ),
      ),
    );
  }
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
