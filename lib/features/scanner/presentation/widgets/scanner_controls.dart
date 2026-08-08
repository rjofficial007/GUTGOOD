import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerTopControls extends StatelessWidget {
  const ScannerTopControls({super.key, required this.scannerController});
  final MobileScannerController scannerController;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: EdgeInsets.only(
        top: MediaQuery.paddingOf(context).top + AppSizes.p10,
        bottom: AppSizes.p20,
        left: AppSizes.p16,
        right: AppSizes.p16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: AppStrings.closeScanner,
            icon: Icon(
              AppIcons.x,
              color: AppPalette.white,
              size: AppSizes.icon28,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
          ),
          ValueListenableBuilder(
            valueListenable: scannerController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isTorchOn
                    ? AppStrings.turnTorchOff
                    : AppStrings.turnTorchOn,
                icon: Icon(
                  isTorchOn ? AppIcons.zap : AppIcons.zapOff,
                  color: AppPalette.white,
                  size: AppSizes.icon28,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  scannerController.toggleTorch();
                },
              );
            },
          ),
        ],
      ),
    ),
  );
}

class ScannerBottomControls extends StatelessWidget {
  const ScannerBottomControls({
    super.key,
    required this.modePageController,
    required this.currentMode,
    required this.isProcessing,
    required this.modes,
    required this.onGalleryTap,
    required this.onShutterTap,
    required this.onModeChanged,
    required this.onSwitchCamera,
  });

  final PageController modePageController;
  final ScannerMode currentMode;
  final bool isProcessing;
  final List<ScannerModeOption> modes;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final Function(int) onModeChanged;
  final VoidCallback onSwitchCamera;

  @override
  Widget build(BuildContext context) => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + AppSizes.p10,
        top: AppSizes.p20,
      ),
      color: AppPalette.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _GalleryButton(onTap: onGalleryTap),
                _ShutterButton(
                  onTap: onShutterTap,
                  isActive: true,
                  isProcessing: isProcessing,
                ),
                _CameraSwitchButton(onTap: onSwitchCamera),
              ],
            ),
          ),
          Gap.h24,
          _ModeSelector(
            controller: modePageController,
            currentMode: currentMode,
            modes: modes,
            onPageChanged: onModeChanged,
          ),
          const _SelectionIndicator(),
          Gap.h8,
        ],
      ),
    ),
  );
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      HapticFeedback.lightImpact();
      onTap();
    },
    child: Tooltip(
      message: AppStrings.pickFromGallery,
      child: Container(
        width: AppSizes.p44,
        height: AppSizes.p44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.r8),
          border: Border.all(color: AppPalette.white, width: AppSizes.p2),
        ),
        child: Icon(
          AppIcons.image,
          color: AppPalette.white,
          size: AppSizes.icon24,
        ),
      ),
    ),
  );
}

class _CameraSwitchButton extends StatelessWidget {
  const _CameraSwitchButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppStrings.switchCamera,
    icon: Icon(
      AppIcons.refreshCw,
      color: AppPalette.white,
      size: AppSizes.icon32,
    ),
    onPressed: () {
      HapticFeedback.lightImpact();
      onTap();
    },
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({
    required this.controller,
    required this.currentMode,
    required this.modes,
    required this.onPageChanged,
  });

  final PageController controller;
  final ScannerMode currentMode;
  final List<ScannerModeOption> modes;
  final Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.p40,
    child: PageView.builder(
      controller: controller,
      itemCount: modes.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final modeItem = modes[index];
        return _ModeItem(
          label: modeItem.label,
          isActive: currentMode == modeItem.mode,
          onTap: () {
            HapticFeedback.mediumImpact();
            controller.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        );
      },
    ),
  );
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: isActive,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppPalette.white : AppPalette.white70,
            fontSize: AppSizes.s11,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    ),
  );
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator();
  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.p4,
    height: AppSizes.p4,
    decoration: const BoxDecoration(
      color: AppPalette.white,
      shape: BoxShape.circle,
    ),
  );
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({
    this.onTap,
    required this.isActive,
    required this.isProcessing,
  });
  final VoidCallback? onTap;
  final bool isActive;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.capturePhoto,
    button: true,
    enabled: isActive && !isProcessing,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppSizes.w80,
        height: AppSizes.w80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.white, width: AppSizes.p4 + 1),
        ),
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: isProcessing ? AppPalette.white70 : AppPalette.white,
            shape: BoxShape.circle,
          ),
          child: isProcessing
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppPalette.black,
                    strokeWidth: AppSizes.p2,
                  ),
                )
              : null,
        ),
      ),
    ),
  );
}
