class ApiConstants {
  const ApiConstants._();

  /// Open Food Facts requires a custom User-Agent on EVERY call, and rate-limits
  /// per caller (product GET ~100/min, search ~10/min; abuse leads to IP bans).
  /// Without one the app is indistinguishable from a scraper and can be blocked,
  /// and OFF has no way to contact us if we misbehave.
  /// Keep this identifiable — app name plus a way to reach you.
  ///
  /// Product/search HTTP is delegated to the official `openfoodfacts` package,
  /// which builds its own header from `OpenFoodAPIConfiguration.userAgent`
  /// (set in `OffServiceImpl`) — this string remains for any direct calls
  /// (e.g. the Search-a-licious fallback via Dio).
  static const userAgent = 'GutGood/1.0 (https://gutgood.app)';

  /// Default URL of the secure OpenAI proxy Cloud Function.
  ///
  /// PRD §3d: devices must NEVER hold the OpenAI key. All AI traffic goes
  /// through this function. Override per-environment via Remote Config
  /// (`ai_proxy_url`) without an app release.
  static const aiProxyUrl = 'https://us-central1-gutgood-app-9242d.cloudfunctions.net/aiProxy';

  // Google Sign-In Web Client ID (for Android ID token exchange and iOS server auth)
  static const googleServerClientId = '1089693952703-om7gdrj1a46u6p9s6km0njq9g72ufjhn.apps.googleusercontent.com';

  // Magic Link URL (Authorized Domain for Continue URL)
  static const magicLinkUrl = 'https://gutgood-app-9242d.firebaseapp.com/auth-completed';
}
