import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/extensions.dart';
import 'package:gutgood/core/utils/logger_service.dart' show AppLogger;
import 'package:gutgood/features/scanner/domain/repositories/scanner_repository.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/usage_service.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/paywall_bottom_sheet.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/widgets/auth_bottom_sheets.dart';

enum ScannerMode { barcode, food, menu, label }

class _ScannerModeOption {
  final ScannerMode mode;
  final String label;
  const _ScannerModeOption({required this.mode, required this.label});
}

class SuperScannerScreen extends StatefulWidget {
  final ScannerMode initialMode;
  const SuperScannerScreen({super.key, this.initialMode = ScannerMode.barcode});

  @override
  State<SuperScannerScreen> createState() => _SuperScannerScreenState();
}

class _SuperScannerScreenState extends State<SuperScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  late PageController _modePageController;
  late ScannerMode _currentMode;
  bool _isProcessing = false;
  final bool _isBatchMode = false;
  final List<ScanResult> _sessionScans = [];
  final ImagePicker _picker = ImagePicker();
  bool _hasPermission = true;
  final GlobalKey _repaintKey = GlobalKey();
  bool _showModeIntro = false;
  Timer? _introTimer;

  final List<_ScannerModeOption> _modes = const [
    _ScannerModeOption(mode: ScannerMode.menu, label: AppStrings.restaurantMenuLabel),
    _ScannerModeOption(mode: ScannerMode.barcode, label: AppStrings.productBarcodeLabel),
    _ScannerModeOption(mode: ScannerMode.label, label: AppStrings.ingredientsLabel),
    _ScannerModeOption(mode: ScannerMode.food, label: AppStrings.mealSnapLabel),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentMode = widget.initialMode;
    final int defaultIndex = _modes.indexWhere((m) => m.mode == _currentMode);
    _modePageController = PageController(viewportFraction: 0.35, initialPage: defaultIndex != -1 ? defaultIndex : 0);

    _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back, torchEnabled: false);
    _checkPermission();
    _loadSavedMode();
    _triggerModeIntro();
  }

  void _triggerModeIntro() {
    _introTimer?.cancel();
    setState(() => _showModeIntro = true);
    _introTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showModeIntro = false);
    });
  }

  Future<void> _loadSavedMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedModeName = prefs.getString('last_scanner_mode');
    if (savedModeName != null) {
      final mode = ScannerMode.values.firstWhere((m) => m.name == savedModeName, orElse: () => ScannerMode.food);
      final index = _modes.indexWhere((m) => m.mode == mode);
      if (index != -1 && mounted) {
        setState(() => _currentMode = mode);
        _modePageController.jumpToPage(index);
      }
    }
  }

  Future<void> _saveMode(ScannerMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_scanner_mode', mode.name);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {}

  Future<void> _handleBarcode(String barcode, {Uint8List? capturedImage}) async {
    final notifier = context.read<ScannerNotifier>();
    final authNotifier = context.read<GutAuthNotifier>();
    setState(() => _isProcessing = true);
    HapticFeedback.lightImpact();

    if (!_isBatchMode && mounted) {
      context.push(AppRoutes.scanningAnimation);
    }

    try {
      final canScan = await sl<UsageService>().canScan();
      if (!canScan) {
        if (mounted) {
          context.pop();
          if (authNotifier.isAnonymous) {
            showAuthBottomSheet(context, customMessage: AppStrings.chatAuthMessage);
          } else {
            showPaywallBottomSheet(context, onProceedWithLimited: () {});
          }
        }
        return;
      }

      final result = await notifier.processBarcode(barcode, capturedImage: capturedImage);

      if (result != null) {
        if (mounted) {
          if (_isBatchMode) {
            setState(() => _sessionScans.insert(0, result));
            HapticFeedback.mediumImpact();
          } else {
            // 🟡 Professional Flow: Use go() to switch branches and reset the stack.
            // This prevents duplicate key errors when pushing branch routes from global overlays.
            context.go(AppRoutes.scanResult, extra: {'scanData': result.toMap()});
          }
        }
      } else {
        if (capturedImage != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.productNotFoundAnalyzing), behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2)));
          final aiResult = await notifier.processImage(capturedImage, mode: _currentMode.name);
          if (mounted) {
            if (aiResult != null) {
              context.go(AppRoutes.scanResult, extra: {'scanData': aiResult.toMap()});
            } else {
              context.pop(); // Pop ScanningAnimation
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.couldNotAnalyzeVision)));
            }
          }
          return;
        }

        if (!_isBatchMode && mounted) {
          context.pop();
          final choice = await context.push(AppRoutes.productNotFound);
          if (choice == 'TRIGGER_CAMERA') {
            setState(() => _currentMode = ScannerMode.label);
          }
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.analyzingProductInfo}: $barcode')));
        }
      }
    } on ScanAnalysisException {
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.productFoundAiFailed), behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      AppLogger.error('Scanner: Error: $e');
      if (!_isBatchMode && mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.failedToAnalyzeProduct)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _capturePhoto() async {
    if (_isProcessing) return;
    final authNotifier = context.read<GutAuthNotifier>();
    final canScan = await sl<UsageService>().canScan();
    if (!canScan) {
      if (mounted) {
        if (authNotifier.isAnonymous) {
          showAuthBottomSheet(context, customMessage: AppStrings.chatAuthMessage);
        } else {
          showPaywallBottomSheet(context, onProceedWithLimited: () {});
        }
      }
      return;
    }

    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      if (_currentMode == ScannerMode.barcode) {
        final tempFile = File('${Directory.systemTemp.path}/temp_barcode.png');
        await tempFile.writeAsBytes(bytes);
        final BarcodeCapture? result = await _scannerController.analyzeImage(tempFile.path);
        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.displayValue;
          if (code != null) {
            await _handleBarcode(code, capturedImage: bytes);
            _cleanupTempFile(tempFile);
            return;
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.noBarcodeDetected), behavior: SnackBarBehavior.floating));
        }
        _cleanupTempFile(tempFile);
        setState(() => _isProcessing = false);
      } else {
        if (mounted) {
          context.pop({'type': _currentMode.name, 'bytes': bytes});
        }
      }
    } catch (e) {
      AppLogger.error('Capture error: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final canScan = await sl<UsageService>().canScan();
    if (!canScan) {
      if (mounted) {
        final authNotifier = context.read<GutAuthNotifier>();
        if (authNotifier.isAnonymous) {
          showAuthBottomSheet(context, customMessage: AppStrings.chatAuthMessage);
        } else {
          showPaywallBottomSheet(context, onProceedWithLimited: () {});
        }
      }
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      if (_currentMode == ScannerMode.barcode) {
        final BarcodeCapture? result = await _scannerController.analyzeImage(image.path);
        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.displayValue;
          if (code != null) {
            await _handleBarcode(code, capturedImage: bytes);
            return;
          }
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.noBarcodeInGallery)));
      } else {
        if (mounted) context.pop({'type': 'gallery', 'bytes': bytes});
      }
    }
  }

  void _cleanupTempFile(File file) {
    try {
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      AppLogger.warning('Scanner: Temp file cleanup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            key: _repaintKey,
            child: ClipRect(
              child: MobileScanner(
                controller: _scannerController,
                onDetect: _onDetect,
                fit: BoxFit.cover, // 🟢 Fix: Ensure camera fills screen without stretching
              ),
            ),
          ),
          _buildTopControls(),
          _buildBottomControls(),
          _buildScanningFrame(),
          if (_showModeIntro) _buildModeIntroOverlay(),
          if (_isBatchMode && _sessionScans.isNotEmpty) _buildBatchList(),
        ],
      ),
    );
  }

  Widget _buildModeIntroOverlay() {
    final String label = _modes.firstWhere((m) => m.mode == _currentMode).label.toUpperCase();

    return Center(
      child: IgnorePointer(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (child, animation) {
            final rotate = Tween<double>(begin: math.pi / 2, end: 0.0).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: AnimatedBuilder(
                animation: rotate,
                builder: (context, child) {
                  return Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(rotate.value),
                    alignment: Alignment.center,
                    child: child,
                  );
                },
                child: child,
              ),
            );
          },
          child: Text(
            label,
            key: ValueKey<String>('intro-$_currentMode-$label'),
            textAlign: TextAlign.center,
            style: context.displayLg.copyWith(
              fontSize: 50.0.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -2.5,
              height: 1.0,
              color: AppPalette.white,
              shadows: [Shadow(color: AppPalette.black.withValues(alpha: 0.6), blurRadius: 30, offset: const Offset(0, 4))],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(top: context.padding.top + AppSizes.p10, bottom: AppSizes.p20, left: AppSizes.p16, right: AppSizes.p16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: AppStrings.closeScanner,
              icon: Icon(AppIcons.x, color: AppPalette.white, size: AppSizes.icon28),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
            ValueListenableBuilder(
              valueListenable: _scannerController,
              builder: (context, state, child) {
                final bool isTorchOn = state.torchState == TorchState.on;
                return IconButton(
                  tooltip: isTorchOn ? AppStrings.turnTorchOff : AppStrings.turnTorchOn,
                  icon: Icon(isTorchOn ? AppIcons.zap : AppIcons.zapOff, color: AppPalette.white, size: AppSizes.icon28),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _scannerController.toggleTorch();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningFrame() {
    if (_hasPermission) return const SizedBox.shrink();
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r20),
              child: Image.asset(AppAssets.appIcon, height: AppSizes.p100, width: AppSizes.p100),
            ),
            Gap.h32,
            Text(
              AppStrings.allowCameraAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(color: AppPalette.white, fontWeight: FontWeight.bold, fontSize: AppSizes.s22),
            ),
            Gap.h16,
            Text(
              AppStrings.cameraAccessSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppPalette.white70, height: 1.4),
            ),
            Gap.h32,
            GestureDetector(
              onTap: _requestPermission,
              child: Text(
                AppStrings.openSettings,
                style: context.bodyBold.copyWith(color: AppPalette.blueLink, fontSize: AppSizes.s16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(bottom: context.padding.bottom + AppSizes.p10, top: AppSizes.p20),
        color: AppPalette.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _pickFromGallery();
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
                        child: Icon(AppIcons.image, color: AppPalette.white, size: AppSizes.icon24),
                      ),
                    ),
                  ),
                  _ShutterButton(onTap: _capturePhoto, isActive: true, isProcessing: _isProcessing),
                  IconButton(
                    tooltip: AppStrings.switchCamera,
                    icon: Icon(AppIcons.refreshCw, color: AppPalette.white, size: AppSizes.icon32),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _scannerController.switchCamera();
                    },
                  ),
                ],
              ),
            ),
            Gap.h24,
            SizedBox(
              height: AppSizes.p40,
              child: PageView.builder(
                controller: _modePageController,
                itemCount: _modes.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentMode = _modes[index].mode;
                  });
                  HapticFeedback.selectionClick();
                  _saveMode(_currentMode);
                  _triggerModeIntro();
                },
                itemBuilder: (context, index) {
                  final modeItem = _modes[index];
                  return _ModeItem(
                    label: modeItem.label,
                    isActive: _currentMode == modeItem.mode,
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      _modePageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                  );
                },
              ),
            ),
            Container(
              width: AppSizes.p4,
              height: AppSizes.p4,
              decoration: const BoxDecoration(color: AppPalette.white, shape: BoxShape.circle),
            ),
            Gap.h8,
          ],
        ),
      ),
    );
  }

  Widget _buildBatchList() {
    return Positioned(
      bottom: AppSizes.p180,
      left: 0,
      right: 0,
      child: SizedBox(
        height: AppSizes.p100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
          itemCount: _sessionScans.length,
          itemBuilder: (context, index) {
            final scan = _sessionScans[index];
            return _BatchCard(scanData: scan);
          },
        ),
      ),
    );
  }
}

class _ModeItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _ModeItem({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(color: isActive ? AppPalette.white : AppPalette.white70, fontSize: AppSizes.s11, fontWeight: isActive ? FontWeight.w800 : FontWeight.w700, letterSpacing: 0.8),
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isActive, isProcessing;
  const _ShutterButton({this.onTap, required this.isActive, required this.isProcessing});

  @override
  Widget build(BuildContext context) {
    return Semantics(
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
          child: Container(
            decoration: BoxDecoration(color: isProcessing ? AppPalette.white70 : AppPalette.white, shape: BoxShape.circle),
            child: isProcessing
                ? Center(
                    child: CircularProgressIndicator(color: AppPalette.black, strokeWidth: AppSizes.p2),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

class _BatchCard extends StatelessWidget {
  final ScanResult scanData;
  const _BatchCard({required this.scanData});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.w140,
      margin: EdgeInsets.only(right: AppSizes.p12),
      padding: EdgeInsets.all(AppSizes.p8),
      decoration: BoxDecoration(color: context.appColorScheme.cardBackground, borderRadius: BorderRadius.circular(AppSizes.r16)),
      child: Row(
        children: [
          Container(
            width: AppSizes.p40,
            height: AppSizes.p40,
            decoration: BoxDecoration(color: context.appColorScheme.elevatedSurface, borderRadius: BorderRadius.circular(AppSizes.r8)),
            child: scanData.imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.r8),
                    child: CachedNetworkImage(imageUrl: scanData.imageUrl!, fit: BoxFit.cover),
                  )
                : Icon(AppIcons.package, size: AppSizes.icon20),
          ),
          Gap.w8,
          Expanded(
            child: Text(
              scanData.productName,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
