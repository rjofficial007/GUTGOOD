import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/app_routes.dart';
import 'package:gutgood/features/scanner/presentation/providers/scanner_notifier.dart';
import 'package:provider/provider.dart';

/// Handles image results for screens that launch the scanner outside Chat.
Future<void> openScannerAndProcessResult(BuildContext context, String mode) async {
  final result = await context.push<Object?>(AppRoutes.scannerPath(mode));
  if (!context.mounted || result is! Map) return;

  final bytes = result['bytes'];
  if (bytes is! Uint8List || bytes.isEmpty) return;

  final scan = await context.read<ScannerNotifier>().processImage(bytes, mode: result['type'] as String? ?? mode);
  if (!context.mounted || scan == null) return;
  await context.push(AppRoutes.scanResult, extra: ScanResultArgs(scanData: scan));
}
