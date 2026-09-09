import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stable `saved_foods` doc ID for a product (P2-6).
///
/// Barcodes are globally unique, so they key directly; everything else keys
/// on a hash of the normalized name (case/whitespace-insensitive), so
/// "Chobani Yogurt" re-scanned next week toggles the SAME doc instead of
/// batch-updating every history instance. Never contains `/`, so it's always
/// a valid single-segment doc ID.
String savedFoodKey({String? barcode, required String productName}) {
  final code = barcode?.trim() ?? '';
  if (code.isNotEmpty) return 'b_${code.replaceAll('/', '_')}';
  final normalized = productName.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return 'n_${sha256.convert(utf8.encode(normalized)).toString().substring(0, 16)}';
}
