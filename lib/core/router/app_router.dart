import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/features/auth/presentation/pages/email_login_screen.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/chat/presentation/pages/chat_screen.dart';
import 'package:gutgood/features/history/presentation/pages/saved_foods_screen.dart';
import 'package:gutgood/features/history/presentation/pages/scan_history_screen.dart';
import 'package:gutgood/features/home/presentation/pages/main_shell.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_history_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/weekly_recap_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insight_detail_screen.dart';
import 'package:gutgood/features/logs/presentation/pages/symptom_check_in_screen.dart';
import 'package:gutgood/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/nutrition_facts_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/product_not_found_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/scan_result_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/cycle_phase_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/goals_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/lifestyle_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/notifications_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/profile_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/sensitivities_screen.dart';
import 'package:gutgood/features/splash/presentation/pages/splash_screen.dart';
import 'package:gutgood/features/welcome/presentation/pages/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/scanner/presentation/pages/manual_barcode_screen.dart';
import '../../features/scanner/presentation/pages/scanning_animation_screen.dart';
import '../../features/scanner/presentation/pages/super_scanner_screen.dart';
import '../di/injection_container.dart';
import '../services/app_state_service.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorChatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final GlobalKey<NavigatorState> _shellNavigatorInsightsKey = GlobalKey<NavigatorState>(debugLabel: 'insights');
final GlobalKey<NavigatorState> _shellNavigatorHistoryKey = GlobalKey<NavigatorState>(debugLabel: 'history');
final GlobalKey<NavigatorState> _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  static final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: sl<GutAuthNotifier>(),
    redirect: (context, state) async {
      final authNotifier = context.read<GutAuthNotifier>();
      final appState = sl<AppStateService>();
      final prefs = sl<SharedPreferences>();

      // 🟢 Fix: Hold redirects while a merge is pending resolution.
      if (appState.pendingMergeConflict.value != null || authNotifier.isMerging) {
        return null;
      }

      final bool onboarded = prefs.getBool('onboarded') ?? false;
      final bool loggedIn = authNotifier.isAuthenticated;

      final bool isSplash = state.matchedLocation == AppRoutes.splash;
      final bool isWelcome = state.matchedLocation == AppRoutes.welcome;
      final bool isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final bool isLogin = state.matchedLocation == AppRoutes.login;

      // Don't redirect during splash initialization
      if (isSplash) return null;

      if (!loggedIn) {
        if (isWelcome || isLogin) return null;
        return AppRoutes.welcome;
      }

      if (!onboarded) {
        if (isOnboarding) return null;
        return AppRoutes.onboarding;
      }

      // If already logged in and onboarded, and trying to access welcome/onboarding
      if (isWelcome || isOnboarding || isLogin) {
        return AppRoutes.chat;
      }

      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const EmailLoginScreen()),

      // Main Application Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _shellNavigatorChatKey,
            routes: [GoRoute(path: AppRoutes.chat, builder: (context, state) => const ChatScreen())],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInsightsKey,
            routes: [
              GoRoute(path: AppRoutes.insights, builder: (context, state) => const InsightsScreen()),
              GoRoute(
                path: AppRoutes.weeklyRecap,
                builder: (context, state) {
                  final insightMap = state.extra as Map<String, dynamic>?;
                  return WeeklyRecapScreen(insight: insightMap != null ? AIInsight.fromMap(insightMap) : null);
                },
              ),
              GoRoute(
                path: AppRoutes.insightDetail,
                builder: (context, state) {
                  final insightMap = state.extra as Map<String, dynamic>;
                  return InsightDetailScreen(insight: AIInsight.fromMap(insightMap));
                },
              ),
              GoRoute(path: AppRoutes.insightHistory, builder: (context, state) => const InsightsHistoryScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(path: AppRoutes.history, builder: (context, state) => const ScanHistoryScreen()),
              GoRoute(path: AppRoutes.savedFoods, builder: (context, state) => const SavedFoodsScreen()),
              GoRoute(
                path: AppRoutes.scanResult,
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  final scanDataMap = extra['scanData'] as Map<String, dynamic>;
                  return ScanResultScreen(scanData: ScanResult.fromMap(scanDataMap), heroTag: extra['heroTag'] as String?);
                },
              ),
              GoRoute(
                path: AppRoutes.nutritionFacts,
                builder: (context, state) {
                  final scanDataMap = state.extra as Map<String, dynamic>;
                  return NutritionFactsScreen(scanData: ScanResult.fromMap(scanDataMap));
                },
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfileKey,
            routes: [
              GoRoute(path: AppRoutes.profile, builder: (context, state) => const ProfileScreen()),
              GoRoute(
                path: AppRoutes.goals,
                builder: (context, state) => GoalsScreen(activeGoals: (state.extra as List).cast<String>()),
              ),
              GoRoute(
                path: AppRoutes.sensitivities,
                builder: (context, state) => SensitivitiesScreen(activeSensitivities: (state.extra as List).cast<String>()),
              ),
              GoRoute(
                path: AppRoutes.lifestyle,
                builder: (context, state) => LifestyleScreen(activeLifestyle: (state.extra as List).cast<String>()),
              ),
              GoRoute(path: AppRoutes.notifications, builder: (context, state) => const NotificationsScreen()),
              GoRoute(
                path: AppRoutes.cyclePhase,
                builder: (context, state) => CyclePhaseScreen(currentPhase: state.extra as String?),
              ),
            ],
          ),
        ],
      ),

      // Global Full-Screen Overlays
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.scanner,
        builder: (context, state) {
          final modeName = state.pathParameters['mode'];
          final mode = ScannerMode.values.firstWhere((m) => m.name == modeName, orElse: () => ScannerMode.label);
          return SuperScannerScreen(initialMode: mode);
        },
      ),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.scanningAnimation, builder: (context, state) => const ScanningAnimationScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.manualBarcode, builder: (context, state) => const ManualBarcodeScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.productNotFound, builder: (context, state) => const ProductNotFoundScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.symptomCheckIn, builder: (context, state) => const SymptomCheckInScreen()),
    ],
  );
}

