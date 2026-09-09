import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Stable 16-hex-char content hash (audit §E: `sha256_16`).
///
/// Used as the idempotency key for image uploads: identical bytes always
/// hash identically, so re-uploads (retry, regenerate, re-scan of the same
/// photo) collapse onto one Storage object and one cached URL.
String imageHash(Uint8List bytes) => sha256.convert(bytes).toString().substring(0, 16);

/// Extracts the `<hash>` identity from a canonical food-image URL
/// (`.../food_images/<hash>.jpg?...`, raw or URL-encoded). Returns null for
/// any other shape (legacy timestamp names, mocks) so callers can fall back.
String? imageHashFromFoodUrl(String url) {
  final match = RegExp('food_images%2F([0-9a-f]{16})\\.jpg|food_images/([0-9a-f]{16})\\.jpg').firstMatch(url);
  if (match == null) return null;
  return match.group(1) ?? match.group(2);
}
