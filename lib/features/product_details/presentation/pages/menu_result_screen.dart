import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:provider/provider.dart';

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
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_menu_result', parameters: {'restaurant_name': _currentData.productName}));

    if (_currentData.scanId != null) {
      final raw = _currentData.rawData ?? {};
      final isFull = raw.containsKey('menu') || raw.containsKey('meal') || raw.containsKey('menuItems');
      if (!isFull) _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) {
      AppLogger.error('MenuResultScreen: Hydration failed', error: e);
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;

    return Scaffold(
      backgroundColor: scheme.cardBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const GutSliverAppBar(title: 'MENU SURVIVAL', centerTitle: true),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _MenuScoreHeroSection(scanData: _currentData),
                Gap.h24,
                if (_currentData.impact.isNotEmpty) ...[
                  _NarrativeSurvivalCard(impact: _currentData.impact),
                  Gap.h24,
                ],
                if (_isRefreshing)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else ...[
                  _MenuAnalysisCard(scanData: _currentData),
                  if (_currentData.allergens != null && _currentData.allergens!.isNotEmpty) ...[
                    Gap.h24,
                    _MenuAllergensCard(allergens: _currentData.allergens!),
                  ],
                  if (_currentData.nutrients != null) ...[
                    Gap.h24,
                    NutritionFactsSection(scanData: _currentData),
                  ],
                ],
                Gap.h24,
                ProductMetadataSection(scanData: _currentData),
                Gap.h40,
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuScoreHeroSection extends StatelessWidget {
  const _MenuScoreHeroSection({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scanData.productName.toUpperCase(),
                      style: context.bodyBold.copyWith(fontSize: 13.sp, color: scheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "RESTAURANT MENU",
                      style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppPalette.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppPalette.orange.withOpacity(0.3)),
                ),
                child: Text(
                  "GUIDE",
                  style: context.bodyBold.copyWith(fontSize: 9.sp, color: AppPalette.orange),
                ),
              ),
            ],
          ),
          Gap.h32,
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180.w,
                height: 120.w,
                child: CustomPaint(
                  painter: _GaugePainter(value: scanData.score / 100, color: AppPalette.orange),
                ),
              ),
              Positioned(
                bottom: 15.w,
                child: Column(
                  children: [
                    Text(
                      "${scanData.score}",
                      style: context.bodyBold.copyWith(fontSize: 40.sp, fontWeight: FontWeight.w900, height: 1, color: scheme.textPrimary),
                    ),
                    Text(
                      "Safety Score",
                      style: context.caption.copyWith(color: scheme.textMuted, fontSize: 10.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NarrativeSurvivalCard extends StatelessWidget {
  const _NarrativeSurvivalCard({required this.impact});
  final String impact;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(color: AppPalette.orange.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(AppIcons.info, size: 16.w, color: AppPalette.orange),
              ),
              Gap.w12,
              Text("SURVIVAL TAKE", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(
            impact,
            style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _MenuAnalysisCard extends StatelessWidget {
  const _MenuAnalysisCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final Map<String, dynamic> raw = scanData.rawData ?? {};
    final Map<String, dynamic> menuBlock = raw.containsKey('menu') ? Map<String, dynamic>.from(raw['menu'] as Map) : raw;
    final List menuItems = menuBlock['menuItems'] ?? [];

    if (menuItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.bookOpen, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("MENU RECOMMENDATIONS", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h24,
          ...menuItems.map((item) => _MenuItem(item: Map<String, dynamic>.from(item is Map ? item : {}))),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.aiResponseBackground,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: scheme.border.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(item['name']?.toString().toUpperCase() ?? 'UNKNOWN', style: context.bodyBold.copyWith(fontSize: 12.sp))),
              if (item['price'] != null) Text(item['price'].toString(), style: context.caption.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          if (item['gutImpact'] != null) ...[
            Gap.h8,
            Row(
              children: [
                Icon(AppIcons.salad, size: 12.w, color: AppPalette.green),
                Gap.w6,
                Expanded(child: Text(item['gutImpact'].toString(), style: context.caption.copyWith(color: AppPalette.green, fontWeight: FontWeight.bold))),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuAllergensCard extends StatelessWidget {
  const _MenuAllergensCard({required this.allergens});
  final String allergens;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: scheme.elevatedSurface,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(color: scheme.error.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.alertTriangle, size: 18.w, color: scheme.error),
              Gap.w12,
              Text("ALLERGEN ALERT", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h16,
          Text(allergens, style: context.bodySm.copyWith(color: scheme.textSecondary, height: 1.4)),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.value, required this.color});
  final double value;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 10.w);
    final radius = size.width / 2;
    final bgPaint = Paint()..color = AppPalette.gray200..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final progressPaint = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2.5;

    for (var i = 0; i <= 60; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final tickLen = i % 10 == 0 ? 10.0 : 5.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        bgPaint,
      );
    }
    final activeTicks = (value * 60).toInt();
    for (var i = 0; i <= activeTicks; i++) {
      final angle = math.pi + (i / 60) * math.pi;
      final tickLen = i % 10 == 0 ? 14.0 : 8.0;
      canvas.drawLine(
        Offset(center.dx + (radius - tickLen) * math.cos(angle), center.dy + (radius - tickLen) * math.sin(angle)),
        Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle)),
        progressPaint,
      );
    }
    final needlePaint = Paint()..color = color.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final indicatorAngle = math.pi + value * math.pi;
    final dotPos = Offset(center.dx + radius * math.cos(indicatorAngle), center.dy + radius * math.sin(indicatorAngle));
    canvas.drawLine(center, dotPos, needlePaint);
    canvas.drawCircle(dotPos, 4, Paint()..color = color);
    canvas.drawCircle(dotPos, 2, Paint()..color = Colors.white);
    canvas.drawCircle(center, 4, Paint()..color = AppPalette.gray100);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
