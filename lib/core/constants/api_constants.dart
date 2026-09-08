class ApiConstants {
  const ApiConstants._();

  // Base URLs (if any)
  static const offBaseUrl = 'https://world.openfoodfacts.org/api/v2';

  /// Open Food Facts requires a custom User-Agent on EVERY call, and rate-limits
  /// per caller (product GET ~100/min, search ~10/min; abuse leads to IP bans).
  /// Without one the app is indistinguishable from a scraper and can be blocked,
  /// and OFF has no way to contact us if we misbehave.
  /// Keep this identifiable — app name plus a way to reach you.
  static const userAgent = 'GutGood/1.0 (https://gutgood.app)';

  /// Fields requested on a barcode lookup.
  ///
  /// Without `fields` OFF returns the ENTIRE product (measured 40-124 KB); with
  /// it the same products come back at 4-12 KB — roughly a 90% saving on every
  /// scan, which matters on mobile data and on a slow supermarket connection.
  static const offProductFields = 'code,product_name,product_name_en,brands,image_url,image_front_url,'
      'nutrition_grades,nutriscore_grade,nutriscore_score,nutriscore_data,nova_group,ecoscore_grade,'
      'ingredients_text,ingredients_text_en,ingredients,additives_n,additives_tags,allergens_tags,allergens,'
      'labels_tags,categories_en,categories,categories_tags,nutriments,nutrient_levels,serving_size,misc_tags';

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
  static const magicLinkUrl = 'https://gutgood-app-9242d.firebaseapp.com/auth-completed';
}
