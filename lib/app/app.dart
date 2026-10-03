import 'package:flutter/material.dart';
import 'package:gutgood/app/router/app_router.dart';
import 'package:gutgood/app/theme/app_theme.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/theme/theme_provider.dart';
import 'package:gutgood/core/utils/responsive.dart';
import 'package:gutgood/core/widgets/offline_banner.dart';
import 'package:gutgood/core/widgets/verification_overlay.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/providers/purchase_provider.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_composer_notifier.dart';
import 'package:gutgood/features/chat/presentation/providers/chat_history_notifier.dart';
import 'package:gutgood/features/history/presentation/providers/history_notifier.dart';
import 'package:gutgood/features/history/presentation/providers/saved_foods_provider.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/features/profile/presentation/providers/profile_provider.dart';
import 'package:gutgood/features/profile/presentation/providers/usage_notifier.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';
import 'package:provider/provider.dart';

/// The application composition root.
///
/// Provider wiring lives here rather than in [main], keeping process startup
/// separate from the widget tree while preserving the existing singleton
/// lifetimes and provider order.
class GutGoodApp extends StatelessWidget {
  const GutGoodApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => sl<ThemeNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<GutAuthNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ProfileNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<UsageNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ChatHistoryNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ChatComposerNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<InsightsNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ScannerNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<PurchaseProvider>()),
      ChangeNotifierProvider(create: (_) => sl<HistoryNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<SavedFoodsProvider>()),
    ],
    child: const _GutGoodShell(),
  );
}

class _GutGoodShell extends StatefulWidget {
  const _GutGoodShell();

  @override
  State<_GutGoodShell> createState() => _GutGoodShellState();
}

class _GutGoodShellState extends State<_GutGoodShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Firestore handles connectivity restoration automatically.
    sl<InternetConnectionChecker>().startListening();
  }

  @override
  void dispose() {
    sl<InternetConnectionChecker>().stopListening();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      sl<InternetConnectionChecker>().checkConnection();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = context.watch<ThemeNotifier>();

    return MaterialApp.router(
      routerConfig: AppRouter.router,
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeNotifier.themeMode,
      builder: (context, child) {
        Responsive.init(context);

        return GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
              const Positioned.fill(child: VerificationOverlay()),
            ],
          ),
        );
      },
    );
  }
}
