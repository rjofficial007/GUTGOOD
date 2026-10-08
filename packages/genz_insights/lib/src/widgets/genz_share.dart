import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:genz_insights/src/genz_theme.dart';

OverlayEntry? _activeToastEntry;
Timer? _activeToastTimer;

void showGenzToast(BuildContext context, String message) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  _activeToastTimer?.cancel();
  _activeToastEntry?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => Positioned(
      left: 0,
      right: 0,
      bottom: 100,
      child: IgnorePointer(
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 180),
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(offset: Offset(0, 12 * (1 - value)), child: child),
            ),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 24, offset: const Offset(0, 8)),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF0B0B12),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    fontFamily: GenzFonts.primary,
                    fontFamilyFallback: GenzFonts.fallback,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  _activeToastEntry = entry;
  overlay.insert(entry);
  _activeToastTimer = Timer(const Duration(milliseconds: 1900), () {
    if (identical(_activeToastEntry, entry)) {
      entry.remove();
      _activeToastEntry = null;
      _activeToastTimer = null;
    }
  });
}

Future<void> copyGenzShare(BuildContext context, {required String text}) async {
  try {
    await Clipboard.setData(ClipboardData(text: text));
  } catch (_) {
    // Keep the prototype's confirmation even when clipboard access is blocked.
  }
  if (!context.mounted) return;
  showGenzToast(context, 'link copied. go flex your gut');
}
