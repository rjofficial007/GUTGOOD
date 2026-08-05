import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/off_service.dart';
import 'package:gutgood/core/services/prompts.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:uuid/uuid.dart';

class ManualBarcodeScreen extends StatefulWidget {
  const ManualBarcodeScreen({super.key});

  @override
  State<ManualBarcodeScreen> createState() => _ManualBarcodeScreenState();
}

class _ManualBarcodeScreenState extends State<ManualBarcodeScreen> {
  final TextEditingController _controller = TextEditingController();

  Future<void> _searchProduct() async {
    final barcode = _controller.text.trim();
    if (barcode.isEmpty) return;

    await sl<AnalyticsService>().logEvent(name: 'manual_barcode_search_started', parameters: {'barcode': barcode});

    final canScan = await sl<UsageService>().canScan();
    if (!canScan) {
      if (mounted) {
        unawaited(showPaywallBottomSheet(context, onProceedWithLimited: () {}));
      }
      return;
    }

    if (!mounted) return;
    unawaited(context.push(AppRoutes.scanningAnimation));

    try {
      final scanData = await sl<OffService>().getProduct(barcode);

      if (scanData != null) {
        unawaited(sl<AnalyticsService>().logEvent(name: 'manual_barcode_search_success', parameters: {'product_name': scanData.productName}));
        final profile = await sl<FirestoreService>().getUserMetadata();
        final cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? AppStrings.phaseLuteal) : AppStrings.notSpecified;

        final prompt = Prompts.productAnalysisPrompt(productData: scanData.toMap(), userGoals: profile?.goals ?? [], userSensitivities: profile?.sensitivities ?? [], cyclePhase: cyclePhase);

        // usageType 'scan': counted once, server-side, by the aiProxy.
        final aiResultStr = await sl<AiService>().generateContent(prompt: prompt, systemInstruction: Prompts.barcodeAnalysisSystemInstruction, usageType: 'scan');
        final aiData = (jsonDecode(aiResultStr) as Map<String, dynamic>)
          ..['imageUrl'] ??= scanData.imageUrl
          ..['barcode'] ??= scanData.barcode
          ..['nutrients'] ??= scanData.nutrients
          ..['source'] = 'barcode';

        final userMsg = ChatMessage(
          localId: const Uuid().v4(),
          role: 'user',
          text: '${AppStrings.manuallyEnteredBarcode}${scanData.productName}',
          scanData: ScanResult.fromMap(aiData),
          source: 'barcode',
          time: DateTime.now(),
        );

        await sl<FirestoreService>().saveMessage(userMsg);

        // 🟢 Fix: Ensure manual scans are also saved to scan_history for Insights/Consistency
        await sl<FirestoreService>().saveToScanHistory(userMsg.scanData!);
        unawaited(sl<NotificationService>().schedulePostMealCheckIn());
        unawaited(sl<NotificationService>().scheduleNoMealLoggedReminder());
        sl<AppStateService>().notifyChatUpdated();

        if (mounted) {
          // 🟡 Professional Flow: Use go() to switch branches and reset the stack.
          context.go(AppRoutes.scanResult, extra: {'scanData': userMsg.scanData!.toMap()});
        }
      } else {
        unawaited(sl<AnalyticsService>().logEvent(name: 'manual_barcode_search_not_found', parameters: {'barcode': barcode}));
        if (mounted) {
          context
            ..pop()
            ..pushReplacement(AppRoutes.productNotFound);
        }
      }
    } catch (e) {
      AppLogger.error('Error fetching product: $e');
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.errorAnalyzingProduct)));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    body: CustomScrollView(
      slivers: [
        GutSliverAppBar(
          title: AppStrings.enterBarcode,
          leading: IconButton(
            icon: Icon(AppIcons.chevronLeft, color: context.appColorScheme.textPrimary),
            onPressed: () => context.pop(),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: EdgeInsets.all(AppSizes.p24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.enterBarcode,
                  style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: AppSizes.s18),
                ),
                Gap.h8,
                Text(
                  AppStrings.enterBarcodeSubtitle,
                  style: context.caption.copyWith(color: context.appColorScheme.textSecondary, fontWeight: FontWeight.w500),
                ),
                Gap.h32,
                GutTextField(controller: _controller, keyboardType: TextInputType.number, style: context.title, prefixIcon: AppIcons.barcode, hintText: AppStrings.enterBarcodeHint),
                Gap.h16,
                Container(
                  padding: EdgeInsets.all(AppSizes.p12),
                  decoration: BoxDecoration(
                    color: context.appColorScheme.success.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppSizes.r12),
                    border: Border.all(color: context.appColorScheme.success.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(AppIcons.info, size: AppSizes.icon16, color: context.appColorScheme.success),
                      Gap.w12,
                      Expanded(
                        child: Text(
                          AppStrings.barcodeHelpText,
                          style: context.bodySm.copyWith(color: context.appColorScheme.success, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                GutButton(label: AppStrings.searchProduct, onTap: _searchProduct),
                Gap.h20,
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
