import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/usage_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/ai_service.dart';
import '../../../../core/services/off_service.dart';
import '../../../../core/services/prompts.dart';

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

    final canScan = await sl<UsageService>().canScan();
    if (!canScan) {
      if (mounted) {
        showPaywallBottomSheet(context, onProceedWithLimited: () {});
      }
      return;
    }

    if (!mounted) return;
    context.push('/scanning-animation');

    try {
      final scanData = await sl<OffService>().getProduct(barcode);

      if (scanData != null) {
        final profile = await sl<FirestoreService>().getUserMetadata();
        final String cyclePhase = (profile?.cycleSyncEnabled == true) ? (profile?.cyclePhase ?? AppStrings.phaseLuteal) : AppStrings.notSpecified;

        final String prompt = Prompts.productAnalysisPrompt(productData: scanData.toMap(), userGoals: profile?.goals ?? [], userSensitivities: profile?.sensitivities ?? [], cyclePhase: cyclePhase);

        // usageType 'scan': counted once, server-side, by the aiProxy.
        final aiResultStr = await sl<AiService>().generateContent(prompt: prompt, systemInstruction: Prompts.barcodeAnalysisSystemInstruction, usageType: 'scan');
        final aiData = jsonDecode(aiResultStr);
        aiData['imageUrl'] ??= scanData.imageUrl;
        aiData['barcode'] ??= scanData.barcode;
        aiData['nutrients'] ??= scanData.nutrients;
        aiData['source'] = 'barcode';

        final userMsg = ChatMessage(
          localId: const Uuid().v4(),
          role: 'user',
          text: '${AppStrings.manuallyEnteredBarcode}${scanData.productName}',
          scanData: ScanResult.fromMap(aiData),
          source: 'barcode',
          time: DateTime.now(),
        );

        await sl<FirestoreService>().saveMessage(userMsg);

        if (mounted) {
          context.pop();
          context.pushReplacement('/scan-result', extra: {'scanData': userMsg.scanData!.toMap()});
        }
      } else {
        if (mounted) {
          context.pop();
          context.pushReplacement('/product-not-found');
        }
      }
    } catch (e) {
      Log.e('Error fetching product: $e');
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.errorAnalyzingProduct)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  Text(AppStrings.enterBarcode, style: context.title.copyWith(fontWeight: FontWeight.w800, fontSize: 18)),
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
}
