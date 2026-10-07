class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String onboarding = '/onboarding';
  static const String login = '/login';

  // Shell Routes
  static const String chat = '/home/chat';
  static const String insights = '/home/insights';
  static const String history = '/home/history';
  static const String profile = '/home/profile';

  // Insights Sub-routes
  static const String insightDetail = '/insight-detail';
  static const String highlightDetail = '/highlight-detail';
  static const String insightHistory = '/insight-history';
  static const String insightGenz = '/insight-genz';
  static const String patternDetail = '/pattern-detail';
  static const String smartInsightDetail = '/smart-insight-detail';
  static const String fiberSynergyDetail = '/fiber-synergy-detail';
  static const String foodIntelligence = '/food-intelligence';
  static const String notificationArchive = '/notification-archive';

  // History Sub-routes
  static const String savedFoods = '/saved-foods';
  static const String allScans = '/all-scans';
  static const String scanResult = '/scan-result';
  static const String symptomDetail = '/symptom-detail';
  static const String additiveDetail = '/additive-detail';
  static const String scanListDetail = '/scan-list-detail';
  static const String additivesList = '/additives-list';
  static const String swapDetail = '/swap-detail';

  // Profile Sub-routes
  static const String goals = '/goals';
  static const String sensitivities = '/sensitivities';
  static const String lifestyle = '/lifestyle';
  static const String notifications = '/notifications';
  static const String cyclePhase = '/cycle-phase';

  // Overlays
  static const String scanner = '/scanner/:mode';
  static const String scanningAnimation = '/scanning-animation';
  static const String productNotFound = '/product-not-found';

  // Helper to build scanner path with mode
  static String scannerPath(String mode) => '/scanner/$mode';
}

// Forced update to resolve sync issue.
