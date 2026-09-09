import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scan_summary_sheet.dart';
import 'package:gutgood/features/scanner/presentation/widgets/scanner_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperScannerScreen extends StatefulWidget {
  const SuperScannerScreen({super.key, this.initialMode});
  final ScannerMode? initialMode;

  @override
  State<SuperScannerScreen> createState() => _SuperScannerScreenState();
}

class _SuperScannerScreenState extends State<SuperScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  late PageController _modePageController;
  late ScannerMode _currentMode;
  final bool _isBatchMode = false;
  final ImagePicker _picker = ImagePicker();
  bool _hasPermission = true;
  final GlobalKey _repaintKey = GlobalKey();
  ScanningState _scanningState = ScanningState.searching;
  String? _guidanceError;
  Timer? _autoCaptureTimer;
  bool _isSheetOpen = false;

  final List<ScannerModeOption> _modes = const [
    ScannerModeOption(mode: ScannerMode.menu, label: AppStrings.restaurantMenuLabel),
    ScannerModeOption(mode: ScannerMode.barcode, label: AppStrings.productBarcodeLabel),
    ScannerModeOption(mode: ScannerMode.label, label: AppStrings.ingredientsLabel),
    ScannerModeOption(mode: ScannerMode.food, label: AppStrings.mealSnapLabel),
  ];

  bool _isCheckingQuota = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentMode = widget.initialMode ?? ScannerMode.barcode;
    final defaultIndex = _modes.indexWhere((m) => m.mode == _currentMode);
    _modePageController = PageController(viewportFraction: 0.4, initialPage: defaultIndex != -1 ? defaultIndex : 0);

    _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back, torchEnabled: false, autoStart: true);

    unawaited(_checkPermission());
    unawaited(_initAndCheckQuota());
  }

  Future<void> _initAndCheckQuota() async {
    if (!mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (widget.initialMode == null) {
        final savedModeName = prefs.getString('last_scanner_mode');
        if (savedModeName != null) {
          final mode = ScannerMode.values.firstWhere((m) => m.name == savedModeName, orElse: () => ScannerMode.barcode);
          final savedIndex = _modes.indexWhere((m) => m.mode == mode);
          if (savedIndex != -1) {
            _currentMode = mode;
            _modePageController.dispose();
            _modePageController = PageController(viewportFraction: 0.4, initialPage: savedIndex);
          }
        }
      } else {
        await prefs.setString('last_scanner_mode', widget.initialMode!.name);
      }
    } catch (e) {
      debugPrint('Scanner: Failed to load saved mode: $e');
    }

    if (!mounted) return;
    await QuotaGuard.check(context, type: QuotaType.scan, popOnBlock: true);
    if (mounted) {
      setState(() {
        _isCheckingQuota = false;
      });
    }
  }

  Future<void> _saveMode(ScannerMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_scanner_mode', mode.name);
    } catch (e) {
      debugPrint('Scanner: Failed to save mode preference: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scannerController.value.isInitialized) return;

    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_checkPermission());
        unawaited(_scannerController.start());
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        unawaited(_scannerController.stop());
        break;
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.status;
    if (mounted) setState(() => _hasPermission = status.isGranted);
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) unawaited(openAppSettings());
    if (mounted) {
      setState(() => _hasPermission = status.isGranted);
      if (status.isGranted) unawaited(_scannerController.start());
    }
  }

  @override
  void dispose() {
    _autoCaptureTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _modePageController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_currentMode != ScannerMode.barcode || _isSheetOpen) return;
    if (_scanningState == ScanningState.scanning || _scanningState == ScanningState.detected || _scanningState == ScanningState.ready) return;

    final barcode = capture.barcodes.firstOrNull?.displayValue ?? capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null) {
      setState(() => _scanningState = ScanningState.detected);
      unawaited(HapticFeedback.mediumImpact());

      // 📸 Professional Capture: Immediately grab the frame when a barcode is locked
      _captureFrameBytes().then((imageBytes) {
        if (mounted && _scanningState == ScanningState.detected && !_isSheetOpen) {
          setState(() => _scanningState = ScanningState.ready);
          unawaited(_handleBarcode(barcode, capturedImage: imageBytes));
        }
      });
    }
  }

  Future<void> _handleBarcode(String barcode, {Uint8List? capturedImage}) async {
    if (!mounted || _isSheetOpen) return;
    final notifier = context.read<ScannerNotifier>();

    final product = await notifier.fetchBarcodeProduct(barcode);

    if (product != null) {
      if (mounted) _showSummarySheet(product, capturedImage);
    } else {
      if (mounted) {
        // A null product offline means "couldn't reach the database", not
        // "product doesn't exist" — say so.
        final message = notifier.lastErrorWasOffline ? AppStrings.offlineMessage : AppStrings.productNotFound;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
      }
    }
  }

  void _showSummarySheet(OffProduct product, Uint8List? capturedImage) {
    if (_isSheetOpen) return;
    setState(() => _isSheetOpen = true);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppPalette.transparent,
      isScrollControlled: true,
      builder: (context) => ScanSummarySheet(product: product, capturedImage: capturedImage),
    ).then((_) {
      if (mounted) {
        setState(() {
          _isSheetOpen = false;
          _scanningState = ScanningState.searching;
        });
      }
    });
  }

  Future<Uint8List?> _captureFrameBytes() async {
    final context = _repaintKey.currentContext;
    if (context == null) return null;

    try {
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final mq = MediaQuery.of(context);
        final pixelRatio = mq.devicePixelRatio;
        final fullImage = await boundary.toImage(pixelRatio: pixelRatio);

        // Calculate the cutout area in logical pixels
        final cutoutRect = ScannerOverlay.getCutoutRect(mq.size, _currentMode);

        // Convert logical pixels to physical pixels for cropping
        final physicalRect = Rect.fromLTRB(
          (cutoutRect.left * pixelRatio).floorToDouble(),
          (cutoutRect.top * pixelRatio).floorToDouble(),
          (cutoutRect.right * pixelRatio).ceilToDouble(),
          (cutoutRect.bottom * pixelRatio).ceilToDouble(),
        );

        // Crop the image
        final croppedImage = await _cropImage(fullImage, physicalRect);
        final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null && byteData.lengthInBytes > 0) {
          final bytes = byteData.buffer.asUint8List();
          debugPrint('Scanner: Successfully captured and cropped image. Size: ${bytes.lengthInBytes ~/ 1024}KB');
          return bytes;
        }
      }
    } catch (e, st) {
      debugPrint('Scanner: RepaintBoundary capture or crop error: $e');
      debugPrint('$st');
    }

    try {
      final fallbackImage = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (fallbackImage != null) return await fallbackImage.readAsBytes();
    } catch (e) {
      debugPrint('Scanner: Camera picker fallback failed: $e');
    }
    return null;
  }

  Future<ui.Image> _cropImage(ui.Image image, Rect rect) async {
    // Clamp the rect to the image bounds to prevent crashes
    final src = Rect.fromLTRB(
      rect.left.clamp(0, image.width.toDouble()),
      rect.top.clamp(0, image.height.toDouble()),
      rect.right.clamp(0, image.width.toDouble()),
      rect.bottom.clamp(0, image.height.toDouble()),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final paint = Paint();
    canvas.drawImageRect(image, src, Rect.fromLTWH(0, 0, src.width, src.height), paint);

    final picture = recorder.endRecording();
    return picture.toImage(src.width.toInt(), src.height.toInt());
  }

  Future<void> _capturePhoto() async {
    final notifier = context.read<ScannerNotifier>();
    if (notifier.isProcessing) return;
    if (!mounted) return;

    try {
      final bytes = await _captureFrameBytes();
      if (bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.couldNotAnalyzeVision), behavior: SnackBarBehavior.floating));
        return;
      }

      await notifier.handlePhotoCapture(
        bytes: bytes,
        mode: _currentMode.name,
        isBatchMode: _isBatchMode,
        analyzeBarcodeInImage: (path) async {
          final result = await _scannerController.analyzeImage(path);
          return result?.barcodes.firstOrNull?.displayValue ?? result?.barcodes.firstOrNull?.rawValue;
        },
        onBarcodeFound: (code, img) => _handleBarcode(code, capturedImage: img),
        onImageCaptured: (img, mode) {
          if (!mounted) return;
          if (context.canPop()) {
            context.pop({'type': mode, 'bytes': img});
          } else {
            unawaited(notifier.processImage(img, mode: mode));
          }
        },
        onError: (message) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
        },
        onHaptic: () => unawaited(HapticFeedback.lightImpact()),
      );
    } catch (e) {
      debugPrint('Scanner: Capture error: $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.failedToAnalyzeProduct), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _pickFromGallery() async {
    if (!mounted) return;
    final notifier = context.read<ScannerNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (image == null) return;
      final bytes = await image.readAsBytes();

      await notifier.handlePhotoCapture(
        bytes: bytes,
        mode: _currentMode.name,
        isBatchMode: _isBatchMode,
        analyzeBarcodeInImage: (path) async {
          final result = await _scannerController.analyzeImage(path);
          return result?.barcodes.firstOrNull?.displayValue ?? result?.barcodes.firstOrNull?.rawValue;
        },
        onBarcodeFound: (code, img) => _handleBarcode(code, capturedImage: img),
        onImageCaptured: (img, mode) {
          if (mounted) {
            if (router.canPop()) {
              router.pop({'type': mode, 'bytes': img});
            } else {
              unawaited(notifier.processImage(img, mode: mode));
            }
          }
        },
        onError: (message) {
          if (mounted) messenger.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
        },
        onHaptic: () => unawaited(HapticFeedback.lightImpact()),
      );
    } catch (e) {
      debugPrint('Scanner: Gallery pick error: $e');
      messenger.showSnackBar(const SnackBar(content: Text(AppStrings.failedToAnalyzeProduct), behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingQuota) return const Scaffold(backgroundColor: AppPalette.black);
    if (!_hasPermission) return const _PermissionOverlay();

    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Consumer<ScannerNotifier>(
      builder: (context, notifier, _) {
        if (notifier.isProcessing && _scanningState != ScanningState.scanning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _scanningState = ScanningState.scanning);
          });
        } else if (!notifier.isProcessing && _scanningState == ScanningState.scanning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _scanningState = ScanningState.searching);
          });
        }

        return Scaffold(
          backgroundColor: AppPalette.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _CameraPreview(repaintKey: _repaintKey, scannerController: _scannerController, onDetect: _onDetect),
              ScannerOverlay(mode: _currentMode, state: _scanningState, errorText: _guidanceError),

              Positioned(
                top: topPadding + AppSizes.p10,
                left: AppSizes.p16,
                right: AppSizes.p16,
                child: _ScannerTopBar(scannerController: _scannerController, currentMode: _currentMode, modes: _modes),
              ),

              Positioned(
                bottom: bottomPadding + AppSizes.p20,
                left: 0,
                right: 0,
                child: _ScannerBottomDock(
                  modePageController: _modePageController,
                  currentMode: _currentMode,
                  isProcessing: notifier.isProcessing,
                  modes: _modes,
                  onGalleryTap: _pickFromGallery,
                  onShutterTap: _capturePhoto,
                  onModeChanged: (index) {
                    setState(() => _currentMode = _modes[index].mode);
                    unawaited(_saveMode(_currentMode));
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CameraPreview extends StatelessWidget {
  const _CameraPreview({required this.repaintKey, required this.scannerController, required this.onDetect});
  final GlobalKey repaintKey;
  final MobileScannerController scannerController;
  final Function(BarcodeCapture) onDetect;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    key: repaintKey,
    child: ClipRect(
      child: MobileScanner(controller: scannerController, onDetect: onDetect, fit: BoxFit.cover),
    ),
  );
}

class _ScannerTopBar extends StatelessWidget {
  const _ScannerTopBar({required this.scannerController, required this.currentMode, required this.modes});
  final MobileScannerController scannerController;
  final ScannerMode currentMode;
  final List<ScannerModeOption> modes;

  @override
  Widget build(BuildContext context) {
    final modeLabel = modes.firstWhere((m) => m.mode == currentMode).label;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _SimpleIconButton(icon: AppIcons.x, onTap: () => context.pop()),
        Text(
          modeLabel.toUpperCase(),
          style: AppTextStyles.bodySm.copyWith(color: AppPalette.white, fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        ValueListenableBuilder(
          valueListenable: scannerController,
          builder: (context, state, child) {
            final isTorchOn = state.torchState == TorchState.on;
            return _SimpleIconButton(icon: isTorchOn ? AppIcons.zap : AppIcons.zapOff, iconColor: isTorchOn ? AppPalette.lime : AppPalette.white, onTap: scannerController.toggleTorch);
          },
        ),
      ],
    );
  }
}

class _SimpleIconButton extends StatelessWidget {
  const _SimpleIconButton({required this.icon, this.iconColor = AppPalette.white, required this.onTap});
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      unawaited(HapticFeedback.lightImpact());
      onTap();
    },
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Icon(icon, color: iconColor, size: 24),
    ),
  );
}

class _ScannerBottomDock extends StatelessWidget {
  const _ScannerBottomDock({
    required this.modePageController,
    required this.currentMode,
    required this.isProcessing,
    required this.modes,
    required this.onGalleryTap,
    required this.onShutterTap,
    required this.onModeChanged,
  });

  final PageController modePageController;
  final ScannerMode currentMode;
  final bool isProcessing;
  final List<ScannerModeOption> modes;
  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final Function(int) onModeChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        height: 44,
        child: PageView.builder(
          controller: modePageController,
          itemCount: modes.length,
          onPageChanged: onModeChanged,
          padEnds: true,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final modeItem = modes[index];
            final isActive = currentMode == modeItem.mode;
            return Center(
              child: Opacity(
                opacity: isActive ? 1.0 : 0.4,
                child: Text(
                  modeItem.label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption.copyWith(fontSize: 11.0.sp, color: AppPalette.white, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 16),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _SimpleIconButton(icon: AppIcons.image, onTap: onGalleryTap),
            _ShutterButton(onTap: onShutterTap, isActive: true, isProcessing: isProcessing),
            _SimpleIconButton(
              icon: AppIcons.refreshCw,
              onTap: () {
                final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
                state?._scannerController.switchCamera();
              },
            ),
          ],
        ),
      ),
    ],
  );
}

class _PermissionOverlay extends StatelessWidget {
  const _PermissionOverlay();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appColorScheme.cardBackground,
    appBar: AppBar(
      backgroundColor: AppPalette.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(AppIcons.x, color: context.appColorScheme.textPrimary),
        onPressed: () => context.pop(),
      ),
    ),
    body: Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.r20),
              child: Image.asset(AppAssets.appIcon, height: AppSizes.p100, width: AppSizes.p100),
            ),
            Gap.h32,
            Text(
              AppStrings.allowCameraAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(color: context.appColorScheme.textPrimary, fontWeight: FontWeight.bold),
            ),
            Gap.h16,
            Text(
              AppStrings.cameraAccessSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: context.appColorScheme.textSecondary, height: 1.4),
            ),
            Gap.h32,
            GutButton(
              label: AppStrings.allowCameraAccess,
              onTap: () async {
                final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
                await state?._requestPermission();
              },
            ),
            Gap.h10,
            GutButton(
              isOutlined: true,
              label: AppStrings.openSettings,
              onTap: () async {
                unawaited(openAppSettings());
              },
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({this.onTap, required this.isActive, required this.isProcessing});
  final VoidCallback? onTap;
  final bool isActive;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppStrings.capturePhoto,
    button: true,
    enabled: isActive && !isProcessing,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        if (isActive && !isProcessing) unawaited(HapticFeedback.mediumImpact());
      },
      onTap: onTap,
      child: Container(
        width: AppSizes.w80,
        height: AppSizes.w80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.white, width: 5),
        ),
        padding: const EdgeInsets.all(4),
        child: DecoratedBox(
          decoration: BoxDecoration(color: isProcessing ? AppPalette.white70 : AppPalette.white, shape: BoxShape.circle),
          child: isProcessing ? const Center(child: CircularProgressIndicator(color: AppPalette.black, strokeWidth: 2)) : null,
        ),
      ),
    ),
  );
}
