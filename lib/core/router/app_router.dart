import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/constants/app_sizes.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/core/router/route_codec.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_text_styles.dart';
import 'package:gutgood/core/widgets/gut_button.dart';
import 'package:gutgood/features/auth/presentation/pages/email_login_screen.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/chat/presentation/pages/chat_screen.dart';
import 'package:gutgood/features/chat/presentation/pages/notification_archive_screen.dart';
import 'package:gutgood/features/history/presentation/pages/all_scans_screen.dart';
import 'package:gutgood/features/history/presentation/pages/saved_foods_screen.dart';
import 'package:gutgood/features/history/presentation/pages/scan_history_screen.dart';
import 'package:gutgood/features/home/presentation/pages/main_shell.dart';
import 'package:gutgood/features/insights/presentation/pages/highlight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_history_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/insights_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/pattern_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/smart_insight_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/pages/synergy_detail_screen.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/insights/presentation/widgets/bento/insight_bento_screens.dart';
import 'package:gutgood/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/additive_detail_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/additives_list_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/product_not_found_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/scan_list_detail_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/scan_result_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/swap_detail_screen.dart';
import 'package:gutgood/features/product_details/presentation/pages/symptom_detail_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/cycle_phase_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/goals_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/lifestyle_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/notifications_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/profile_screen.dart';
import 'package:gutgood/features/profile/presentation/pages/sensitivities_screen.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/scanner/presentation/pages/scanning_animation_screen.dart';
import 'package:gutgood/features/scanner/presentation/pages/super_scanner_screen.dart';
import 'package:gutgood/features/splash/presentation/pages/splash_screen.dart';
import 'package:gutgood/features/welcome/presentation/pages/welcome_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    extraCodec: const RouteCodec(),
    observers: [sl<AnalyticsService>().getObserver()],
    refreshListenable: Listenable.merge([sl<GutAuthNotifier>(), sl<ProfileNotifier>()]),
    redirect: (context, state) async {
      final authNotifier = context.read<GutAuthNotifier>();
      final profileNotifier = context.read<ProfileNotifier>();
      final appState = sl<AppStateService>();
      final prefs = sl<SharedPreferences>();

      // 🟢 Fix: Hold redirects while a merge is pending resolution OR logout is in progress.
      if (appState.pendingMergeConflict.value != null || authNotifier.isMerging || appState.isLoggingOut.value) {
        return null;
      }

      final loggedIn = authNotifier.isAuthenticated;

      // 🟡 Professional Flow: If logged in but profile isn't initialized yet,
      // stay on the current screen (Splash/Welcome) while we fetch the "onboarded" truth from Firestore.
      if (loggedIn && !profileNotifier.isInitialized) {
        return null;
      }

      // Use Profile as source of truth, fallback to local prefs (for Guest fast-path)
      // 🟢 Fix: Use OR logic to ensure that if EITHER Firestore or Local Prefs says
      // we are onboarded, we don't redirect back to onboarding. This prevents
      // race conditions where the local flag is updated before the Firestore stream.
      final onboarded = (profileNotifier.profile?.onboarded == true) || (prefs.getBool(StorageKeys.onboarded) == true);

      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isWelcome = state.matchedLocation == AppRoutes.welcome;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isLogin = state.matchedLocation == AppRoutes.login;

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

      // 🟡 Professional Flow: Redirect onboarded users to Chat.
      if (loggedIn && onboarded) {
        if (isWelcome || isOnboarding) return AppRoutes.chat;
        // EXCEPTION: Anonymous users on the Login screen are allowed to stay to upgrade their account.
        if (isLogin && !authNotifier.isAnonymous) return AppRoutes.chat;
      }

      // 🔵 Fix: Magic Link / Deep Link routing.
      // If the location contains Firebase Auth internal markers, ignore the URL
      // and return null so it stays on the current screen (Splash/Welcome)
      // while the LinkService handles the background login.
      if (state.uri.toString().contains('__/auth/') || state.uri.toString().contains('firebaseapp.com')) {
        // If we've ALREADY logged in while on this technical URL, go home!
        if (loggedIn) {
          return onboarded ? AppRoutes.chat : AppRoutes.onboarding;
        }
        return null;
      }

      return null;
    },
    errorBuilder: (context, state) {
      // 🟡 Professional Fallback: If we hit an unknown route, stay on the current screen
      // while checking if we should be at home. This handles technical deep links gracefully.
      final auth = context.read<GutAuthNotifier>();
      final profile = context.read<ProfileNotifier>();

      if (auth.isAuthenticated && profile.isInitialized) {
        return const ChatScreen();
      }

      return _UnknownRouteScreen(location: state.uri.toString());
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: AppRoutes.welcome, builder: (context, state) => const WelcomeScreen()),
      GoRoute(path: AppRoutes.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: AppRoutes.login, builder: (context, state) => const EmailLoginScreen()),

      // Main Application Shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(navigationShell: navigationShell),
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
                path: AppRoutes.insightDetail,
                builder: (context, state) {
                  final insight = state.extra is AIInsight ? state.extra as AIInsight : context.read<InsightsNotifier>().latestInsight;
                  if (insight == null) return const InsightsHistoryScreen();
                  return InsightDetailScreen(insight: insight);
                },
              ),
              GoRoute(
                path: AppRoutes.highlightDetail,
                builder: (context, state) {
                  final args = state.extra is HighlightDetailArgs
                      ? state.extra as HighlightDetailArgs
                      : const HighlightDetailArgs(tag: 'Highlight', emoji: '✨', title: 'Highlight Details', accentColor: 0xFF15803D, backgroundColor: 0xFFDCFCE7);
                  return HighlightDetailScreen(args: args);
                },
              ),
              GoRoute(path: AppRoutes.insightHistory, builder: (context, state) => const InsightsHistoryScreen()),
              GoRoute(
                path: AppRoutes.patternDetail,
                builder: (context, state) {
                  final pattern = state.extra is BodyPattern
                      ? state.extra as BodyPattern
                      : (context.read<InsightsNotifier>().prioritizedPatterns.firstOrNull ??
                            BodyPattern(
                              type: 'Pattern',
                              trigger: 'Meal',
                              reaction: 'Symptom',
                              frequency: 1,
                              confidence: 'Medium',
                              description: 'Pattern details',
                              updatedAt: DateTime.now().toIso8601String(),
                            ));
                  return PatternDetailScreen(pattern: pattern);
                },
              ),
              GoRoute(
                path: AppRoutes.smartInsightDetail,
                builder: (context, state) {
                  final insight = state.extra is InsightSummary
                      ? state.extra as InsightSummary
                      : (context.read<InsightsNotifier>().latestInsight?.topInsight ?? const InsightSummary(title: 'Top Insight', description: 'Insight details', type: 'Pattern'));
                  return SmartInsightDetailScreen(insight: insight);
                },
              ),
              GoRoute(
                path: AppRoutes.fiberSynergyDetail,
                builder: (context, state) {
                  if (state.extra is BodyPattern) {
                    return SynergyDetailScreen(pattern: state.extra as BodyPattern);
                  }
                  return SynergyDetailScreen(insight: state.extra is AIInsight ? state.extra as AIInsight : null);
                },
              ),
              GoRoute(
                path: AppRoutes.foodIntelligence,
                builder: (context, state) => FoodIntelligenceScreen(insight: state.extra is AIInsight ? state.extra as AIInsight : null),
              ),
              GoRoute(path: AppRoutes.notificationArchive, builder: (context, state) => const NotificationArchiveScreen()),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorHistoryKey,
            routes: [
              GoRoute(path: AppRoutes.history, builder: (context, state) => const ScanHistoryScreen()),
              GoRoute(path: AppRoutes.allScans, builder: (context, state) => const AllScansScreen()),
              GoRoute(path: AppRoutes.savedFoods, builder: (context, state) => const SavedFoodsScreen()),
              GoRoute(
                path: AppRoutes.scanResult,
                builder: (context, state) {
                  if (state.extra is ScanResultArgs) {
                    final args = state.extra as ScanResultArgs;
                    return ScanResultScreen(scanData: args.scanData, heroTag: args.heroTag);
                  }
                  if (state.extra is ScanResult) {
                    return ScanResultScreen(scanData: state.extra as ScanResult);
                  }
                  return const ScanHistoryScreen();
                },
              ),

              GoRoute(
                path: AppRoutes.symptomDetail,
                builder: (context, state) {
                  if (state.extra is SymptomLog) {
                    return SymptomDetailScreen(symptom: state.extra as SymptomLog);
                  }
                  return const ScanHistoryScreen();
                },
              ),
              GoRoute(
                path: AppRoutes.additiveDetail,
                builder: (context, state) {
                  if (state.extra is AdditiveConcern) {
                    return AdditiveDetailScreen(concern: state.extra as AdditiveConcern);
                  }
                  return const ScanHistoryScreen();
                },
              ),
              GoRoute(
                path: AppRoutes.scanListDetail,
                builder: (context, state) {
                  if (state.extra is ScanListDetailArgs) {
                    return ScanListDetailScreen(args: state.extra as ScanListDetailArgs);
                  }
                  return const ScanHistoryScreen();
                },
              ),
              GoRoute(
                path: AppRoutes.additivesList,
                builder: (context, state) {
                  if (state.extra is AdditiveListArgs) {
                    return AdditivesListScreen(args: state.extra as AdditiveListArgs);
                  }
                  return const ScanHistoryScreen();
                },
              ),
              GoRoute(
                path: AppRoutes.swapDetail,
                builder: (context, state) {
                  if (state.extra is ProductSwap) {
                    return SwapDetailScreen(swap: state.extra as ProductSwap);
                  }
                  const defaultSwap = ProductSwap(title: 'Better Choice', subtitle: 'A healthier alternative.', imageKeyword: 'healthy food', tag: 'Swap');
                  return const SwapDetailScreen(swap: defaultSwap);
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
                builder: (context, state) {
                  final goals = state.extra is List ? (state.extra as List).cast<String>() : <String>[];
                  return GoalsScreen(activeGoals: goals);
                },
              ),
              GoRoute(
                path: AppRoutes.sensitivities,
                builder: (context, state) {
                  final sensitivities = state.extra is List ? (state.extra as List).cast<String>() : <String>[];
                  return SensitivitiesScreen(activeSensitivities: sensitivities);
                },
              ),
              GoRoute(
                path: AppRoutes.lifestyle,
                builder: (context, state) {
                  final lifestyle = state.extra is List ? (state.extra as List).cast<String>() : <String>[];
                  return LifestyleScreen(activeLifestyle: lifestyle);
                },
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
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/scanner', builder: (context, state) => const SuperScannerScreen()),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: AppRoutes.scanner,
        builder: (context, state) {
          final modeName = state.pathParameters['mode'];
          final mode = modeName != null ? ScannerMode.values.where((m) => m.name == modeName).firstOrNull : null;
          return SuperScannerScreen(initialMode: mode);
        },
      ),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.scanningAnimation, builder: (context, state) => const ScanningAnimationScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: AppRoutes.productNotFound, builder: (context, state) => const ProductNotFoundScreen()),
    ],
  );
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.location});
  final String location;

  @override
  Widget build(BuildContext context) {
    // If it's an external/auth link, just show a verifying state instead of error
    final isAuthLink = location.contains('__/auth/') || location.contains('firebaseapp.com');

    // 🟢 Fix: Make the error screen reactive so it can "Teleport" as soon as login finishes.
    return Consumer2<GutAuthNotifier, ProfileNotifier>(
      builder: (context, auth, profile, _) {
        if (isAuthLink && auth.isAuthenticated && profile.isInitialized) {
          // Success! Jump to home.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go(profile.profile?.onboarded == true ? AppRoutes.chat : AppRoutes.onboarding);
          });
        }

        return Scaffold(
          backgroundColor: context.appColorScheme.cardBackground,
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(AppSizes.p40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isAuthLink) ...[
                    const CircularProgressIndicator(),
                    Gap.h24,
                    Text(AppStrings.confirmingIdentity, style: context.bodyBold),
                  ] else ...[
                    Icon(AppIcons.alertTriangle, size: 48, color: context.appColorScheme.error),
                    Gap.h24,
                    Text(AppStrings.pageNotFound, style: context.title),
                    Gap.h12,
                    Text('${AppStrings.routeNotFoundPrefix}$location', textAlign: TextAlign.center, style: context.caption),
                    Gap.h32,
                    GutButton(label: AppStrings.backToSafety, onTap: () => context.go(AppRoutes.chat)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
