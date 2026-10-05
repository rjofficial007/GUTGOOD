import 'dart:async';

import 'package:dio/dio.dart';

/// Optional Pexels image lookup for evaluating food photos separately from
/// `core/utils/image_utils.dart`.
///
/// This trial key is embedded for local testing only. A key compiled into a
/// Flutter app can be extracted, so replace this with a backend proxy before
/// shipping.
abstract final class PexelsService {
  static const _apiKey = 'fQYf3AGCuysBkcPzXuO1e5DFNjPwlzS8SJPcE6RuSXsJn0PWQzrzaWDi';
  static final Map<String, String> _imageCache = {};
  static final Map<String, Future<String?>> _imageRequests = {};
  static final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 8), receiveTimeout: const Duration(seconds: 8)));

  /// Returns the first matching Pexels image URL, or null if unavailable.
  static Future<String?> getDynamicImageUrl(String? keyword) {
    final foodName = keyword?.trim();
    final query = foodName == null || foodName.isEmpty ? 'healthy food' : '$foodName food';
    if (_apiKey.isEmpty) return Future.value(null);
    final cacheKey = query.toLowerCase();
    final cached = _imageCache[cacheKey];
    if (cached != null) return Future.value(cached);
    return _imageRequests.putIfAbsent(cacheKey, () async {
      try {
        final imageUrl = await _fetchImage(query);
        if (imageUrl != null) {
          if (_imageCache.length >= 100) _imageCache.remove(_imageCache.keys.first);
          _imageCache[cacheKey] = imageUrl;
        }
        return imageUrl;
      } finally {
        _imageRequests.remove(cacheKey)?.ignore();
      }
    });
  }

  static Future<String?> _fetchImage(String query) async {
    try {
      final response = await _dio.get<Object?>(
        'https://api.pexels.com/v1/search',
        queryParameters: {'query': query, 'per_page': 1},
        options: Options(headers: {'Authorization': _apiKey}),
      );
      final body = response.data;
      if (body is! Map<String, dynamic>) return null;

      final Object? photosValue = body['photos'];
      if (photosValue is! List || photosValue.isEmpty) return null;
      final Object? firstPhoto = photosValue.first;
      if (firstPhoto is! Map<String, dynamic>) return null;

      final Object? sourcesValue = firstPhoto['src'];
      if (sourcesValue is! Map<String, dynamic>) return null;

      // Prefer smaller responses for quicker image loads; keep larger sizes
      // as fallbacks for unusual API responses that omit the smaller variants.
      for (final size in ['medium', 'small', 'tiny', 'large', 'large2x']) {
        final Object? value = sourcesValue[size];
        if (value is! String) continue;
        final uri = Uri.tryParse(value);
        if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
          return uri.toString();
        }
      }
    } on DioException {
      return null;
    } catch (_) {
      return null;
    }

    return null;
  }
}
