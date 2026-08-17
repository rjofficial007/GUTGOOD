class ApiConstants {
  const ApiConstants._();

  // Base URLs (if any)
  static const offBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  // Endpoints
  static const productEndpoint = '/product';

  /// Default URL of the secure OpenAI proxy Cloud Function.
  ///
  /// PRD §3d: devices must NEVER hold the OpenAI key. All AI traffic goes
  /// through this function. Override per-environment via Remote Config
  /// (`ai_proxy_url`) without an app release.
  static const aiProxyUrl = 'https://us-central1-gutgood-app-9242d.cloudfunctions.net/aiProxy';

  // Google Sign-In Web Client ID (for Android ID token exchange and iOS server auth)
  static const googleServerClientId = '1089693952703-om7gdrj1a46u6p9s6km0njq9g72ufjhn.apps.googleusercontent.com';

  // Magic Link URL (Authorized Domain for Continue URL)
  // TODO: Update this once custom domain https://gutgoodapp.com is connected in Firebase Hosting
  static const magicLinkUrl = 'https://gutgood-app-9242d.firebaseapp.com/auth-completed';
}
