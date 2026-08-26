import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/core/widgets/gut_app_bar.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';
import 'package:provider/provider.dart';

class LabelResultScreen extends StatefulWidget {
  const LabelResultScreen({super.key, required this.scanData, this.heroTag});
  final ScanResult scanData;
  final String? heroTag;

  @override
  State<LabelResultScreen> createState() => _LabelResultScreenState();
}

class _LabelResultScreenState extends State<LabelResultScreen> {
  late ScanResult _currentData;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _currentData = widget.scanData;
    unawaited(sl<AnalyticsService>().logEvent(name: 'view_label_result', parameters: {'product_name': _currentData.productName}));

    if (_currentData.scanId != null) {
      final hasDetails = _currentData.ingredients.any((i) => i.impact.isNotEmpty || i.colorName != 'gray');
      if (!hasDetails) _refreshData();
    }
  }

  Future<void> _refreshData() async {
    if (_currentData.scanId == null) return;
    setState(() => _isRefreshing = true);
    try {
      final fullData = await sl<HistoryRepository>().getScanById(_currentData.scanId!);
      if (fullData != null && mounted) setState(() => _currentData = fullData);
    } catch (e) {
      AppLogger.error('LabelResultScreen: Hydration failed', error: e);
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
          const GutSliverAppBar(title: 'CLINICAL AUDIT', centerTitle: true),
          SliverPadding(
            padding: EdgeInsets.all(AppSizes.p20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _LabelScoreHeroSection(scanData: _currentData),
                Gap.h24,
                _LabelImpactGrid(scanData: _currentData),
                Gap.h24,
                if (_currentData.impact.isNotEmpty) ...[
                  _NarrativeAuditCard(impact: _currentData.impact),
                  Gap.h24,
                ],
                if (_isRefreshing)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                else ...[
                  _IngredientsAuditCard(scanData: _currentData),
                  Gap.h24,
                  AdditivesSection(scanData: _currentData),
                  if (_currentData.allergens != null && _currentData.allergens!.isNotEmpty) ...[
                    Gap.h24,
                    _AllergensAuditCard(allergens: _currentData.allergens!),
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

class _LabelScoreHeroSection extends StatelessWidget {
  const _LabelScoreHeroSection({required this.scanData});
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
                      "INGREDIENT LABEL",
                      style: context.caption.copyWith(fontSize: 10.sp, color: scheme.textMuted),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppPalette.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppPalette.blue.withOpacity(0.3)),
                ),
                child: Text(
                  "AUDIT",
                  style: context.bodyBold.copyWith(fontSize: 9.sp, color: AppPalette.blue),
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
                  painter: _GaugePainter(value: scanData.score / 100, color: AppPalette.blue),
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
                      "Health Grade",
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

class _LabelImpactGrid extends StatelessWidget {
  const _LabelImpactGrid({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    final l = scanData.nutrientLevels;
    
    String sugarStatus = l?.sugars.toUpperCase() ?? "LOW";
    String saltStatus = l?.salt.toUpperCase() ?? "LOW";

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: "SUGAR LEVEL",
            value: sugarStatus,
            subtitle: "Inflammatory risk",
            icon: AppIcons.flame,
            color: sugarStatus == "HIGH" ? scheme.error : (sugarStatus == "MODERATE" ? scheme.warning : scheme.success),
          ),
        ),
        Gap.w20,
        Expanded(
          child: _StatCard(
            label: "SODIUM",
            value: saltStatus,
            subtitle: "Water retention",
            icon: AppIcons.droplet,
            color: saltStatus == "HIGH" ? scheme.error : (saltStatus == "MODERATE" ? scheme.warning : scheme.success),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.subtitle, required this.icon, required this.color});
  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      height: 150.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(32.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 16.w, color: Colors.black),
              ),
              Row(
                children: [
                  Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                  Gap.w4,
                  Container(width: 4.w, height: 4.w, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                ],
              ),
            ],
          ),
          const Spacer(),
          Text(label, style: context.bodyBold.copyWith(fontSize: 10.sp, color: Colors.black.withOpacity(0.5))),
          Text(value, style: context.bodyBold.copyWith(fontSize: 14.sp, color: Colors.black, height: 1.1)),
          Text(subtitle, style: context.caption.copyWith(fontSize: 9.sp, color: Colors.black.withOpacity(0.5))),
        ],
      ),
    );
  }
}

class _NarrativeAuditCard extends StatelessWidget {
  const _NarrativeAuditCard({required this.impact});
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
                decoration: BoxDecoration(color: AppPalette.blue.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(AppIcons.flaskConical, size: 16.w, color: AppPalette.blue),
              ),
              Gap.w12,
              Text("CLINICAL AUDIT", style: context.bodyBold.copyWith(fontSize: 12.sp, letterSpacing: 0.5, color: scheme.textPrimary)),
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

class _IngredientsAuditCard extends StatelessWidget {
  const _IngredientsAuditCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) {
    final scheme = context.appColorScheme;
    if (scanData.ingredients.isEmpty) return const SizedBox.shrink();

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
              Icon(AppIcons.utensils, size: 18.w, color: scheme.textPrimary),
              Gap.w12,
              Text("INGREDIENTS AUDIT", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
            ],
          ),
          Gap.h24,
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: scanData.ingredients.map((ing) {
               final color = ing.colorName.toLowerCase() == 'red' ? scheme.error : (ing.colorName.toLowerCase() == 'orange' ? scheme.warning : scheme.textPrimary);
               return Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: scheme.aiResponseBackground,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Text(ing.name.toUpperCase(), style: context.bodyBold.copyWith(fontSize: 9.sp, color: color)),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AllergensAuditCard extends StatelessWidget {
  const _AllergensAuditCard({required this.allergens});
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
              Text("ALLERGEN AUDIT", style: context.bodyBold.copyWith(fontSize: 12.sp, color: scheme.textPrimary)),
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
