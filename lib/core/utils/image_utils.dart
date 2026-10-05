import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/services/pexels_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _pexelsPreferenceKey = 'debug_use_pexels_food_images';

/// Defaults to the current Pexels trial; the debug profile toggle can switch
/// back to the previous Bing image search and persists across launches.
final ValueNotifier<bool> usePexelsFoodImages = ValueNotifier(true);
Future<void>? _imageSourcePreferenceLoad;

Future<void> loadImageSourcePreference() => _imageSourcePreferenceLoad ??= () async {
  try {
    usePexelsFoodImages.value = sl<SharedPreferences>().getBool(_pexelsPreferenceKey) ?? true;
  } catch (_) {
    // Keep the default image source if preferences are unavailable.
  }
}();

Future<void> setUsePexelsFoodImages(bool enabled) async {
  await loadImageSourcePreference();
  usePexelsFoodImages.value = enabled;
  try {
    await sl<SharedPreferences>().setBool(_pexelsPreferenceKey, enabled);
  } catch (_) {
    // Keep the current session choice even if persistence fails.
  }
}

/// Resolves a food image from Pexels, falling back to the existing image search.
Future<String> getDynamicImageUrl(String? keyword) async {
  await loadImageSourcePreference();
  if (usePexelsFoodImages.value) {
    final pexelsUrl = await PexelsService.getDynamicImageUrl(keyword);
    if (pexelsUrl != null) return pexelsUrl;
  }
  return getFallbackDynamicImageUrl(keyword);
}

/// Synchronous legacy URL fallback for non-widget callers.
String getFallbackFoodImageUrl(String? keyword) => getFallbackDynamicImageUrl(keyword);

/// Existing search URL retained as a graceful fallback if Pexels is unavailable.
String getFallbackDynamicImageUrl(String? keyword) {
  final query = (keyword ?? 'healthy food').trim();
  if (query.isEmpty) return 'https://placehold.co/400x400/EEE/31343C?text=No+Image';
  return 'https://tse2.mm.bing.net/th?q=${Uri.encodeComponent(query)}&w=400&h=400&c=7&rs=1&p=0&dpr=2&pid=1.7';
}

/// Loads a supplied food image first, otherwise resolves one through Pexels.
class DynamicFoodImage extends StatelessWidget {
  const DynamicFoodImage({
    super.key,
    required this.keyword,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholder,
    this.errorWidget,
  });

  final String keyword;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final suppliedUrl = imageUrl?.trim();
    if (suppliedUrl != null && suppliedUrl.isNotEmpty && !_isPlaceholderUrl(suppliedUrl)) {
      return _networkImage(suppliedUrl);
    }

    return ValueListenableBuilder<bool>(
      valueListenable: usePexelsFoodImages,
      builder: (context, _, _) => FutureBuilder<String>(
        future: getDynamicImageUrl(keyword),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return _placeholder();
          return _networkImage(snapshot.data ?? getFallbackDynamicImageUrl(keyword));
        },
      ),
    );
  }

  Widget _networkImage(String url) => CachedNetworkImage(
    imageUrl: url,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    placeholder: (_, _) => _placeholder(),
    errorWidget: (_, _, _) => errorWidget ?? const Icon(Icons.fastfood_outlined),
  );

  Widget _placeholder() => placeholder ?? const Center(child: CircularProgressIndicator(strokeWidth: 2));

  bool _isPlaceholderUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase();
    return host == 'example.com' || host?.endsWith('.example.com') == true || url.contains('unsplash.com');
  }
}
