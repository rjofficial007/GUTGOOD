import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/services/app_services.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/internet_connection_checker.dart';
import 'package:gutgood/core/services/link_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    final stopwatch = Stopwatch()..start();

    void updateProgress(double value) {
      if (mounted) setState(() => _progress = value);
    }

    try {
      updateProgress(0.1);
      final remoteConfig = sl<RemoteConfigService>();
      final notificationService = sl<NotificationService>();
      final linkService = sl<LinkService>();
      final purchaseService = sl<PurchaseService>();
      final connectionChecker = sl<InternetConnectionChecker>();
      final appService = sl<AppService>();

      // 1. Initialize Remote Config first
      await remoteConfig.init();
      updateProgress(0.3);

      // 2. Parallel initializations
      await Future.wait([notificationService.init(), linkService.init(), purchaseService.initialize()]);
      updateProgress(0.6);

      // 2.5 Mark app opened (schedules daily reminder) after init
      await notificationService.markAppOpened();
      updateProgress(0.7);

      // 3. Connectivity
      await connectionChecker.checkConnection();
      connectionChecker.startListening();
      updateProgress(0.8);

      // 4. Background Data
      await appService.lookupUserCountry();
      updateProgress(0.9);

      // 5. Initial Profile Fetch (if authenticated)
      final authRepository = sl<AuthRepository>();
      if (authRepository.currentUser != null) {
        AppLogger.info('SplashScreen: User authenticated, warming up Firestore cache.');
        await sl<AuthFirestoreService>().getUserMetadata().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            AppLogger.warning('SplashScreen: Firestore warmup timed out. Proceeding with cache.');
            return null;
          },
        );
      }
      updateProgress(1.0);
    } catch (e) {
      AppLogger.error('SplashScreen: Initialization error: $e');
      updateProgress(1.0);
    }

    stopwatch.stop();

    // // Ensure splash shows for at least 2 seconds for branded experience
    final remainingTime = 2000 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    if (mounted) {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _SplashLogo(),
            const SizedBox(height: 80),
            _BootProgressBar(progress: _progress),
          ],
        ),
      ),
    );
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) => Image.asset(
      AppAssets.appIconBg,
      width: 80,
      color: AppPalette.white,
    );
}

class _BootProgressBar extends StatelessWidget {
  const _BootProgressBar({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) => SizedBox(
      width: 120,
      height: 4,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white.withValues(alpha: 0.2),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
}
