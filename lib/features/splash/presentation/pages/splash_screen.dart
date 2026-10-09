import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_assets.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/models/user/user_profile.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/theme/app_palette.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/data/services/link_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/firebase/remote_config_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:gutgood/infrastructure/platform/app_service.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
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
      final authRepository = sl<AuthRepository>();
      final user = authRepository.currentUser;
      if (user != null) {
        AppLogger.info('SplashScreen: User authenticated, warming up Firestore cache.');
        var profileReadTimedOut = false;
        final firestoreService = sl<AuthFirestoreService>();
        final profile = await firestoreService.getUserMetadata().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            profileReadTimedOut = true;
            AppLogger.warning('SplashScreen: Firestore warmup timed out. Proceeding with cache.');
            return null;
          },
        );
        if (profile == null && !profileReadTimedOut) {
          final now = DateTime.now();
          await firestoreService.createUserProfileIfMissing(UserProfile(
            uid: user.uid,
            displayName: user.displayName ?? (user.isAnonymous ? 'Guest' : null),
            email: user.email ?? (user.isAnonymous ? 'No email synced' : null),
            isAnonymous: user.isAnonymous,
            authProvider: user.authProvider ?? (user.isAnonymous ? 'anonymous' : null),
            onboarded: false,
            updatedAt: now,
            createdAt: now,
          ));
          AppLogger.info('SplashScreen: Created missing profile for authenticated user.');
        }
      }
    } catch (e) {
      AppLogger.error('SplashScreen: Initialization error: $e');
    }

    stopwatch.stop();

    // Ensure splash shows for at least 2 seconds for branded experience
    final remainingTime = 2000 - stopwatch.elapsedMilliseconds;
    if (remainingTime > 0) {
      await Future.delayed(Duration(milliseconds: remainingTime));
    }

    if (mounted) {
      context.go(AppRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: AppPalette.black,
    body: Center(child: _SplashLogo()),
  );
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo();

  @override
  Widget build(BuildContext context) => Image.asset(AppAssets.appIconBg, width: 60, color: AppPalette.white);
}
