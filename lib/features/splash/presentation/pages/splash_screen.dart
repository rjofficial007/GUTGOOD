import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/link_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_color_scheme.dart';
import '../../../../core/theme/app_palette.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    try {
      final remoteConfig = sl<RemoteConfigService>();
      final notificationService = sl<NotificationService>();
      final linkService = sl<LinkService>();
      final purchaseService = sl<PurchaseService>();
      final connectionChecker = sl<InternetConnectionChecker>();
      final appService = sl<AppService>();

      // 1. Initialize Remote Config first
      await remoteConfig.init();

      // 2. Parallel initializations
      await Future.wait([notificationService.init(), linkService.init(), purchaseService.initialize()]);

      // 2.5 Mark app opened (schedules daily reminder) after init
      await notificationService.markAppOpened();

      // 3. Connectivity
      await connectionChecker.checkConnection();
      connectionChecker.startListening();

      // 4. Background Data
      await appService.lookupUserCountry();

      // 5. Initial Profile Fetch (if authenticated)
      // Firestore will handle caching and background sync automatically.
      final authRepository = sl<AuthRepository>();
      if (authRepository.currentUser != null) {
        Log.i('SplashScreen: User authenticated, warming up Firestore cache.');
        await sl<FirestoreService>().getUserMetadata().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            Log.w('SplashScreen: Firestore warmup timed out. Proceeding with cache.');
            return null;
          },
        );
      }
    } catch (e) {
      Log.e('SplashScreen: Initialization error: $e');
    }

    stopwatch.stop();

    // Ensure splash shows for at least 2 seconds for branded experience
    final remainingTime = 2000 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    if (mounted) {
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.splashBg,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(AppAssets.appIcon, width: 180.0.w),
                    Gap.h20,
                    SizedBox(
                      width: 50,
                      height: 2,
                      child: LinearProgressIndicator(
                        backgroundColor: context.appColorScheme.border.withValues(alpha: 0.2),
                        color: AppPalette.white,
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
