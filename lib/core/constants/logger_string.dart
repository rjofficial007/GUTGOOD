class AppLoggerStrings {
  // Prevent instantiation
  AppLoggerStrings._();

  // --- Core Logger Prefixes ---
  static const String logPrefix = '[GUTGOOD]';
  static const String logDebug = '🔍 DEBUG:';
  static const String logInfo = 'ℹ️ INFO:';
  static const String logSuccess = '✅ SUCCESS:';
  static const String logError = '💥 ERROR:';
  static const String logWarning = '⚠️ WARNING:';

  // --- Feature Specific Prefixes ---
  static const String logAuth = '🛡️ AUTH:';
  static const String logFirestore = '☁️ FIRESTORE:';
  static const String logAi = '🤖 AI_SERVICE:';
  static const String logScanner = '📸 SCANNER:';
  static const String logStorage = '📂 STORAGE:';
  static const String logInsights = '📊 INSIGHTS:';
  static const String logPayments = '💳 PAYMENTS:';
  static const String logNotifications = '🔔 NOTIFS:';
  static const String logConnectivity = '🌐 NETWORK:';
  static const String logNavigation = '🗺️ ROUTER:';
  static const String logRemoteConfig = '🔥 REMOTE_CONFIG:';
  static const String logTheme = '🎨 THEME:';
  static const String logDeepLink = '🔗 DEEP_LINK:';
  static const String logLifecycle = '🚀 LIFECYCLE:';
  static const String logPremium = '💎 PREMIUM:';
  static const String logMock = '🧪 MOCK_DATA:';

  // --- Common Action Statuses ---
  static const String statusFetching = '📥 Fetching...';
  static const String statusSaving = '💾 Saving...';
  static const String statusUpdating = '🔄 Updating...';
  static const String statusDeleting = '🗑️ Deleting...';
  static const String statusStreaming = '📡 Streaming...';
  static const String statusAnalyzing = '🧠 Analyzing...';
  static const String statusComplete = '✨ Complete';
  static const String statusFailed = '🚫 Failed';
}
