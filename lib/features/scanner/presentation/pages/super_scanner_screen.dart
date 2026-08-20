import 'dart:async';
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
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/quota_guard.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/widgets.dart';
import 'package:gutgood/features/scanner/domain/models/scanner_mode.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SuperScannerScreen extends StatefulWidget {
  const SuperScannerScreen({super.key, this.initialMode = ScannerMode.barcode});
  final ScannerMode initialMode;

  @override
  State<SuperScannerScreen> createState() => _SuperScannerScreenState();
}

class _SuperScannerScreenState extends State<SuperScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _scannerController;
  late PageController _modePageController;
  late ScannerMode _currentMode;
  final bool _isBatchMode = false;
  final List<ScanResult> _sessionScans = [];
  final ImagePicker _picker = ImagePicker();
  bool _hasPermission = true;
  final GlobalKey _repaintKey = GlobalKey();
  bool _showModeIntro = false;
  Timer? _introTimer;

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

    _currentMode = widget.initialMode;
    final defaultIndex = _modes.indexWhere((m) => m.mode == _currentMode);
    _modePageController = PageController(viewportFraction: 0.4, initialPage: defaultIndex != -1 ? defaultIndex : 0);

    _scannerController = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, facing: CameraFacing.back, torchEnabled: false);
    unawaited(_checkPermission());
    unawaited(_loadSavedMode());
    unawaited(_checkQuota());
    _triggerModeIntro();
  }

  Future<void> _checkQuota() async {
    if (!mounted) return;
    await QuotaGuard.check(context, type: QuotaType.scan, popOnBlock: true);
    if (mounted) {
      setState(() {
        _isCheckingQuota = false;
        // If not allowed, QuotaGuard will pop the screen.
      });
    }
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_modePageController.hasClients) {
            _modePageController.jumpToPage(index);
          }
        });
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
      unawaited(openAppSettings());
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
    if (!await QuotaGuard.check(context, type: QuotaType.scan, popOnBlock: true)) return;
    if (!mounted) return;

    final notifier = context.read<ScannerNotifier>();

    await notifier.handleBarcodeScan(
      barcode,
      capturedImage: capturedImage,
      mode: _currentMode.name,
      isBatchMode: _isBatchMode,
      onScanStart: () {
        if (mounted) context.push(AppRoutes.scanningAnimation);
      },
      onSuccess: (result) {
        if (mounted) {
          if (_isBatchMode) {
            setState(() => _sessionScans.insert(0, result));
            unawaited(HapticFeedback.mediumImpact());
          } else {
            context.go(AppRoutes.scanResult, extra: ScanResultArgs(scanData: result));
          }
        }
      },
      onProductNotFound: () async {
        if (!mounted) return;
        if (!_isBatchMode) {
          context.pop(); // Pop ScanningAnimation
          final choice = await context.push(AppRoutes.productNotFound);
          if (choice == 'TRIGGER_CAMERA' && mounted) {
            setState(() => _currentMode = ScannerMode.label);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${AppStrings.analyzingProductInfo}: $barcode')));
        }
      },
      onError: (message) {
        if (mounted) {
          if (!_isBatchMode) context.pop(); // Pop ScanningAnimation
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
        }
      },
      onInfo: (message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
        }
      },
      onHaptic: () => unawaited(HapticFeedback.lightImpact()),
    );
  }

  Future<void> _capturePhoto() async {
    final notifier = context.read<ScannerNotifier>();
    if (notifier.isProcessing) return;
    if (!await QuotaGuard.check(context, type: QuotaType.scan, popOnBlock: true)) return;
    if (!mounted) return;

    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();

      await notifier.handlePhotoCapture(
        bytes: bytes,
        mode: _currentMode.name,
        isBatchMode: _isBatchMode,
        analyzeBarcodeInImage: (path) async {
          final result = await _scannerController.analyzeImage(path);
          return result?.barcodes.firstOrNull?.displayValue;
        },
        onBarcodeFound: (code, img) => _handleBarcode(code, capturedImage: img),
        onImageCaptured: (img, mode) {
          if (mounted) context.pop({'type': mode, 'bytes': img});
        },
        onError: (message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
          }
        },
        onHaptic: () => unawaited(HapticFeedback.mediumImpact()),
      );
    } catch (e) {
      AppLogger.error('Scanner: Capture error: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (!await QuotaGuard.check(context, type: QuotaType.scan, popOnBlock: true)) return;
    if (!mounted) return;

    final notifier = context.read<ScannerNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    final bytes = await image.readAsBytes();

    await notifier.handlePhotoCapture(
      bytes: bytes,
      mode: _currentMode.name,
      isBatchMode: _isBatchMode,
      analyzeBarcodeInImage: (path) async {
        final result = await _scannerController.analyzeImage(path);
        return result?.barcodes.firstOrNull?.displayValue;
      },
      onBarcodeFound: (code, img) => _handleBarcode(code, capturedImage: img),
      onImageCaptured: (img, mode) {
        if (mounted) router.pop({'type': 'gallery', 'bytes': img});
      },
      onError: (message) {
        if (mounted) {
          messenger.showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
        }
      },
      onHaptic: () => unawaited(HapticFeedback.lightImpact()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingQuota) {
      return const Scaffold(backgroundColor: AppPalette.black);
    }

    if (!_hasPermission) {
      return const _PermissionOverlay();
    }

    return Consumer<ScannerNotifier>(
      builder: (context, notifier, _) => Scaffold(
        backgroundColor: AppPalette.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _CameraPreview(repaintKey: _repaintKey, scannerController: _scannerController, onDetect: _onDetect),
            _ScannerTopControls(scannerController: _scannerController),
            _ScannerBottomControls(
              modePageController: _modePageController,
              currentMode: _currentMode,
              isProcessing: notifier.isProcessing,
              modes: _modes,
              onGalleryTap: _pickFromGallery,
              onShutterTap: _capturePhoto,
              onModeChanged: (index) {
                setState(() {
                  _currentMode = _modes[index].mode;
                });
                unawaited(HapticFeedback.selectionClick());
                unawaited(_saveMode(_currentMode));
                _triggerModeIntro();
              },
            ),
            if (_showModeIntro) _ModeIntroOverlay(currentMode: _currentMode, modes: _modes),
            if (_isBatchMode && _sessionScans.isNotEmpty) _BatchScanList(scans: _sessionScans),
          ],
        ),
      ),
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

class _ScannerTopControls extends StatelessWidget {
  const _ScannerTopControls({required this.scannerController});
  final MobileScannerController scannerController;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top + AppSizes.p10, bottom: AppSizes.p20, left: AppSizes.p16, right: AppSizes.p16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            tooltip: AppStrings.closeScanner,
            icon: Icon(AppIcons.x, color: AppPalette.white, size: AppSizes.icon28),
            onPressed: () {
              unawaited(HapticFeedback.lightImpact());
              context.pop();
            },
          ),
          ValueListenableBuilder(
            valueListenable: scannerController,
            builder: (context, state, child) {
              final isTorchOn = state.torchState == TorchState.on;
              return IconButton(
                tooltip: isTorchOn ? AppStrings.turnTorchOff : AppStrings.turnTorchOn,
                icon: Icon(isTorchOn ? AppIcons.zap : AppIcons.zapOff, color: AppPalette.white, size: AppSizes.icon28),
                onPressed: () {
                  unawaited(HapticFeedback.lightImpact());
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

class _ScannerBottomControls extends StatelessWidget {
  const _ScannerBottomControls({
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
  Widget build(BuildContext context) => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Container(
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + AppSizes.p10, top: AppSizes.p20),
      color: AppPalette.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ActionButtonsRow(onGalleryTap: onGalleryTap, onShutterTap: onShutterTap, isProcessing: isProcessing),
          Gap.h24,
          _ModeSelector(controller: modePageController, currentMode: currentMode, modes: modes, onPageChanged: onModeChanged),
          const _SelectionIndicator(),
          Gap.h8,
        ],
      ),
    ),
  );
}

class _ActionButtonsRow extends StatelessWidget {
  const _ActionButtonsRow({required this.onGalleryTap, required this.onShutterTap, required this.isProcessing});

  final VoidCallback onGalleryTap;
  final VoidCallback onShutterTap;
  final bool isProcessing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSizes.p24),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _GalleryButton(onTap: onGalleryTap),
        _ShutterButton(onTap: onShutterTap, isActive: true, isProcessing: isProcessing),
        const _CameraSwitchButton(),
      ],
    ),
  );
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppStrings.pickFromGallery,
    icon: Icon(AppIcons.image, color: AppPalette.white, size: AppSizes.icon32),
    onPressed: () {
      unawaited(HapticFeedback.lightImpact());
      onTap();
    },
  );
}

class _CameraSwitchButton extends StatelessWidget {
  const _CameraSwitchButton();

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: AppStrings.switchCamera,
    icon: Icon(AppIcons.refreshCw, color: AppPalette.white, size: AppSizes.icon32),
    onPressed: () {
      unawaited(HapticFeedback.lightImpact());
      final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
      state?._scannerController.switchCamera();
    },
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.controller, required this.currentMode, required this.modes, required this.onPageChanged});

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
      padEnds: true,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final modeItem = modes[index];
        return _ModeItem(
          label: modeItem.label,
          isActive: currentMode == modeItem.mode,
          onTap: () {
            onPageChanged(index);
            unawaited(HapticFeedback.mediumImpact());
            controller.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
          },
        );
      },
    ),
  );
}

class _SelectionIndicator extends StatelessWidget {
  const _SelectionIndicator();
  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.p6,
    height: AppSizes.p6,
    decoration: BoxDecoration(
      color: AppPalette.white,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AppPalette.white.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
    ),
  );
}

class _PermissionOverlay extends StatelessWidget {
  const _PermissionOverlay();

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppPalette.black,
    appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(AppIcons.x, color: AppPalette.white),
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
              child: Image.asset(AppAssets.appIcon, height: AppSizes.p180, width: AppSizes.p180),
            ),
            Gap.h32,
            Text(
              AppStrings.allowCameraAccess,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingMd.copyWith(color: AppPalette.white, fontWeight: FontWeight.bold),
            ),
            Gap.h16,
            Text(
              AppStrings.cameraAccessSubtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppPalette.white70, height: 1.4),
            ),
            Gap.h32,
            GutButton(
              label: AppStrings.allowCameraAccess,
              onTap: () async {
                final state = context.findAncestorStateOfType<_SuperScannerScreenState>();
                await state?._requestPermission();
              },
            ),
            Gap.h24,
            GestureDetector(
              onTap: () async {
                unawaited(openAppSettings());
              },
              child: Text(
                AppStrings.openSettings,
                style: context.bodyBold.copyWith(color: AppPalette.blueLink, fontSize: AppSizes.s14),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _ModeIntroOverlay extends StatelessWidget {
  const _ModeIntroOverlay({required this.currentMode, required this.modes});
  final ScannerMode currentMode;
  final List<ScannerModeOption> modes;

  @override
  Widget build(BuildContext context) {
    final label = modes.firstWhere((m) => m.mode == currentMode).label.toUpperCase();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSizes.p120),
      child: Center(
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
                  builder: (context, child) => Transform(
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0015)
                      ..rotateX(rotate.value),
                    alignment: Alignment.center,
                    child: child,
                  ),
                  child: child,
                ),
              );
            },
            child: Text(
              label,
              key: ValueKey<String>('intro-$currentMode-$label'),
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
      ),
    );
  }
}

class _BatchScanList extends StatelessWidget {
  const _BatchScanList({required this.scans});
  final List<ScanResult> scans;

  @override
  Widget build(BuildContext context) => Positioned(
    bottom: AppSizes.p180,
    left: 0,
    right: 0,
    child: SizedBox(
      height: AppSizes.p100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: AppSizes.p16),
        itemCount: scans.length,
        itemBuilder: (context, index) {
          final scan = scans[index];
          return _BatchCard(scanData: scan);
        },
      ),
    ),
  );
}

class _ModeItem extends StatelessWidget {
  const _ModeItem({required this.label, required this.isActive, required this.onTap});
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    selected: isActive,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? AppPalette.white : AppPalette.white.withValues(alpha: 0.5),
            fontSize: isActive ? AppSizes.s12 : AppSizes.s11,
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
            letterSpacing: isActive ? 1.0 : 0.8,
          ),
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

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.scanData});
  final ScanResult scanData;

  @override
  Widget build(BuildContext context) => Container(
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
