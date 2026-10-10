part of 'super_scanner_screen.dart';

/// Scanner screen state and capture orchestration.

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
  bool _isCapturingPhoto = false;

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

    // smooth-app scan behavior: drop QR codes / too-short values entirely
    // (no haptic, no state change — the scanner simply keeps searching), and
    // normalize the code (UPC-A → EAN-13, dash stripping) before use.
    final rawCode = capture.barcodes.firstOrNull?.displayValue ?? capture.barcodes.firstOrNull?.rawValue;
    final barcode = BarcodeValidator.normalizeForScan(rawCode);
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
      if (mounted) unawaited(_showSummarySheet(product, capturedImage));
    } else {
      if (mounted) {
        // A null product offline means "couldn't reach the database", not
        // "product doesn't exist" — say so.
        final message = notifier.lastErrorWasOffline ? AppStrings.offlineMessage : AppStrings.productNotFound;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
      }
    }
  }

  Future<void> _showSummarySheet(OffProduct product, Uint8List? capturedImage) async {
    if (_isSheetOpen) return;
    setState(() => _isSheetOpen = true);

    final result = await showModalBottomSheet<ScanResult>(
      context: context,
      backgroundColor: AppPalette.transparent,
      isScrollControlled: true,
      builder: (context) => ScanSummarySheet(product: product, capturedImage: capturedImage),
    );

    if (!mounted) return;

    setState(() {
      _isSheetOpen = false;
      _scanningState = ScanningState.searching;
    });

    if (result != null) {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
        unawaited(router.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: result)));
      } else {
        router.go(AppRoutes.scanResult, extra: ScanResultArgs(scanData: result));
      }
    }
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

  Future<bool> _waitForCameraReady() async {
    bool isReady() => _scannerController.value.isInitialized && _scannerController.value.isRunning;

    if (!await waitForScannerReady(_scannerController) || !mounted || !isReady()) return false;

    // The controller can be running before the platform preview has painted
    // its first camera frame into the RepaintBoundary.
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 150));
    await WidgetsBinding.instance.endOfFrame;
    return mounted && isReady();
  }

  Future<void> _capturePhoto() async {
    final notifier = context.read<ScannerNotifier>();
    if (notifier.isProcessing || _isCapturingPhoto || !mounted) return;

    setState(() => _isCapturingPhoto = true);

    try {
      if (!await _waitForCameraReady()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(AppStrings.failedToAnalyzeProduct), behavior: SnackBarBehavior.floating));
        }
        return;
      }

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
    } finally {
      if (mounted) setState(() => _isCapturingPhoto = false);
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
      if (bytes.isEmpty) {
        messenger.showSnackBar(const SnackBar(content: Text(AppStrings.failedToAnalyzeProduct), behavior: SnackBarBehavior.floating));
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
        fallbackToPhotoWhenBarcodeMissing: true,
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
                  isProcessing: notifier.isProcessing || _isCapturingPhoto,
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
