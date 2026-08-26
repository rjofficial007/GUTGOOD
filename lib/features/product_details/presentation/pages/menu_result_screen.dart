import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/dashboard_widgets.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

class MenuResultScreen extends StatefulWidget {
  const MenuResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<MenuResultScreen> createState() => _MenuResultScreenState();
}

class _MenuResultScreenState extends State<MenuResultScreen> {
  late ScanResult _currentData;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    AppLogger.info('MenuResultScreen: Init with data: ${_currentData.productName}. RawData presence: ${_currentData.rawData != null}');

    unawaited(sl<AnalyticsService>().logEvent(name: 'view_menu_result', parameters: {'restaurant_name': _currentData.productName}));

    if (_currentData.scanId != null) {
      // 🚀 Deep Hydration Check: Even if rawData exists, check if it's "Full" (has menu/meal blocks)
      final raw = _currentData.rawData ?? {};
      final contextBlock = raw.containsKey('rawData') && raw['rawData'] is Map ? Map<String, dynamic>.from(raw['rawData'] as Map) : raw;
      final isFull = contextBlock.containsKey('menu') || contextBlock.containsKey('meal') || contextBlock.containsKey('menuItems');

      if (!isFull) {
        AppLogger.info('MenuResultScreen: Data is partial/missing blocks, triggering hydration for ID: ${_currentData.scanId}');
        _refreshData();
      }
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);

    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) {
        AppLogger.info('MenuResultScreen: Hydration successful. Full rawData keys: ${fullData.rawData?.keys.toList()}');
        setState(() => _currentData = fullData);
      } else {
        AppLogger.warning('MenuResultScreen: Hydration returned null for ID: ${_currentData.scanId}');
      }
    } catch (e) {
      AppLogger.error('MenuResultScreen: Hydration failed', error: e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    // 🚀 High-Resolution Logging for Debugging
    final raw = _currentData.rawData ?? {};
    final hasScan = raw.containsKey('scan');
    final hasMenu = raw.containsKey('menu');
    final hasMeal = raw.containsKey('meal');

    final menuItemsCount = raw['menu']?['menuItems']?.length ?? raw['scan']?['menuItems']?.length ?? raw['menuItems']?.length ?? 0;

    AppLogger.info(
      'MenuResultScreen: Building UI. Restaurant: ${_currentData.productName}, '
      'RawKeys: ${raw.keys.toList()}, '
      'Blocks: [scan:$hasScan, menu:$hasMenu, meal:$hasMeal], '
      'MenuItems: $menuItemsCount',
    );

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: 'MENU SURVIVAL', centerTitle: true),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24, vertical: AppSizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardEntrance(delay: 50, child: _MenuHeader(scanData: _currentData)),
                  Gap.h32,
                  DashboardEntrance(
                    delay: 100,
                    child: ProductImageHeader(
                      scanData: _currentData,
                      heroTag: widget.heroTag,
                      overlay: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (_currentData.impact.isNotEmpty)
                            GlassCard(
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(AppIcons.info, color: AppPalette.white, size: 16),
                                      Gap.w8,
                                      Text(
                                        'SURVIVAL TAKE',
                                        style: context.eyebrow.copyWith(color: AppPalette.white, fontSize: 10.sp),
                                      ),
                                    ],
                                  ),
                                  Gap.h10,
                                  Text(
                                    _currentData.impact,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.bodySm.copyWith(color: Colors.white, fontWeight: FontWeight.w500, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (_isRefreshing)
                    Padding(
                      padding: const EdgeInsets.only(top: 32),
                      child: Center(child: CircularProgressIndicator(color: scheme.textPrimary)),
                    )
                  else ...[
                    Gap.h32,
                    DashboardEntrance(delay: 200, child: MenuAnalysisSection(scanData: _currentData)),
                    if (_currentData.allergens != null && _currentData.allergens!.isNotEmpty) ...[
                      Gap.h32,
                      DashboardEntrance(
                        delay: 250,
                        child: AllergensSection(allergens: _currentData.allergens!, servingSize: _currentData.servingSize),
                      ),
                    ],
                    if (_currentData.nutrients != null) ...[Gap.h32, DashboardEntrance(delay: 280, child: NutritionFactsSection(scanData: _currentData))],
                    Gap.h32,
                    DashboardEntrance(delay: 300, child: ProductMetadataSection(scanData: _currentData)),
                  ],
                  Gap.h40,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    // 🚀 Robust Extraction: The menu data might be in rawData directly or nested in a 'menu' or 'scan' key
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final Map<String, dynamic> scanBlock = raw.containsKey('scan') ? Map<String, dynamic>.from(raw['scan'] as Map) : {};
    final Map<String, dynamic> menuBlock = raw.containsKey('menu') ? Map<String, dynamic>.from(raw['menu'] as Map) : (scanBlock.isNotEmpty ? scanBlock : raw);

    final restaurantName = menuBlock['restaurantName']?.toString() ?? scanBlock['restaurantName']?.toString() ?? scanData.productName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppPalette.orange, borderRadius: BorderRadius.circular(4)),
              child: Text(
                'RESTAURANT MENU',
                style: context.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10.sp),
              ),
            ),
            Gap.w12,
            Text('ORDERING GUIDE', style: context.eyebrow.copyWith(color: scheme.textMuted)),
          ],
        ),
        Gap.h16,
        Text(
          restaurantName.toString().toUpperCase(),
          style: context.displaySm.copyWith(fontWeight: FontWeight.w900, letterSpacing: -1.5, height: 1.0, color: scheme.textPrimary),
        ),
      ],
    );
  }
}
