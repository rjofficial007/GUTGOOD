import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_view.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:provider/provider.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late ScanResult _currentData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_scan_result', parameters: {'product_name': _currentData.productName, 'score': _currentData.score}));

    if (_currentData.scanId != null) {
      final hasDetails = _currentData.impacts.isNotEmpty || _currentData.nutrients != null || _currentData.swaps.isNotEmpty;
      if (!hasDetails || _currentData.displayImageUrl == null) _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) {
        setState(() {
          _currentData = fullData.copyWith(
            userImageUrl: fullData.userImageUrl ?? _currentData.userImageUrl,
          );
        });
      }
    } catch (e) {
      AppLogger.error('ScanResultScreen: Hydration failed', error: e);
    }
  }

  Future<void> _toggleSave() async {
    final provider = context.read<SavedFoodsProvider>();
    await provider.toggleSave(_currentData);
    sl<AppStateService>().notifyProfileUpdated();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profileNotifier = context.watch<ProfileNotifier>();
    final cycleSyncEnabled = profileNotifier.profile?.cycleSyncEnabled ?? false;

    return Consumer<SavedFoodsProvider>(
      builder: (context, savedProvider, _) {
        final isSaved = savedProvider.isSaved(_currentData.productName, barcode: _currentData.barcode);
        return Scaffold(
          backgroundColor: isDark ? scheme.cardBackground : const Color(0xFFFCFCFD),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              GutSliverAppBar(
                title: 'Scan result',
                centerTitle: true,
                actions: [
                  SaveButton(
                    isSaved: isSaved,
                    isLoading: _isLoading,
                    onTap: () async {
                      setState(() => _isLoading = true);
                      try {
                        await _toggleSave();
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: ScanResultView(scanData: _currentData, cycleSyncEnabled: cycleSyncEnabled),
              ),
            ],
          ),
        );
      },
    );
  }
}
