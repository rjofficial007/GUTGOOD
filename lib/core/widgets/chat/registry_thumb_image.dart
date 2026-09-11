import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/constants/app_icons.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/services/firestore/food_image_firestore_service.dart';
import 'package:gutgood/core/theme/app_color_scheme.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// Chat-strip thumbnail that prefers the 320px registry thumb over the
/// 1024px Storage original (§E bandwidth win on history scroll). Resolution
/// is one prefs read on the warm path; until it lands, a placeholder keeps
/// layout stable. Any failure (offline, legacy URL, missing doc) renders
/// the full URL exactly as before — thumbs are strictly an optimization.
class RegistryThumbImage extends StatefulWidget {
  const RegistryThumbImage({super.key, required this.fullUrl, this.hash, required this.size, required this.dark});

  final String fullUrl;
  final String? hash;
  final double size;
  final bool dark;

  @override
  State<RegistryThumbImage> createState() => _RegistryThumbImageState();
}

class _RegistryThumbImageState extends State<RegistryThumbImage> {
  String? _resolved;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    final hash = widget.hash;
    if (hash == null || hash.isEmpty) {
      _done = true;
      return;
    }
    sl<FoodImageService>()
        .resolveThumbUrl(hash: hash, fullUrl: widget.fullUrl)
        .then((url) {
          if (mounted) {
            setState(() {
            _resolved = url;
            _done = true;
          });
          }
        })
        .catchError((_) {
          if (mounted) setState(() => _done = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final placeholder = Container(height: size, width: size, color: widget.dark ? AppPalette.white15 : context.appColorScheme.elevatedSurface);
    if (!_done) return placeholder;
    return CachedNetworkImage(
      imageUrl: _resolved ?? widget.fullUrl,
      height: size,
      width: size,
      fit: BoxFit.cover,
      memCacheWidth: (size * 2).round(),
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => Container(
        height: size,
        width: size,
        color: context.appColorScheme.elevatedSurface,
        child: Icon(AppIcons.image, color: context.appColorScheme.textMuted),
      ),
    );
  }
}
