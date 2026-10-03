import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/di/di_instance.dart';
import 'package:gutgood/core/utils/haptic_helper.dart';
import 'package:gutgood/features/auth/data/services/usage_service.dart';
import 'package:gutgood/features/auth/presentation/pages/paywall_screen.dart';
import 'package:gutgood/features/auth/presentation/providers/auth_provider.dart';
import 'package:gutgood/features/auth/presentation/widgets/auth_bottom_sheets.dart';
import 'package:provider/provider.dart';

enum QuotaType { chat, scan, premium }

/// A centralized utility to guard actions based on user usage limits.
///
/// It automatically handles:
/// 1. Checking [UsageService] for limits.
/// 2. Providing haptic feedback on blocks.
/// 3. Showing [showAuthBottomSheet] for guests or [showPaywallScreen] for registered users.
class QuotaGuard {
  const QuotaGuard._();

  /// Checks if the user has enough quota for the given [type].
  /// Returns `true` if allowed, `false` if blocked.
  ///
  /// [onAuthSuccess] is called if the user successfully authenticates via the auth sheet.
  /// [onProceedWithLimited] is called if the user chooses to continue with limited access from the paywall.
  /// [popOnBlock] if true, will pop the current screen if the quota is exceeded.
  static Future<bool> check(BuildContext context, {required QuotaType type, VoidCallback? onAuthSuccess, VoidCallback? onProceedWithLimited, bool popOnBlock = false}) async {
    final usageService = sl<UsageService>();
    final authNotifier = context.read<GutAuthNotifier>();

    var allowed = false;
    switch (type) {
      case QuotaType.chat:
        allowed = await usageService.canChat();
      case QuotaType.scan:
        allowed = await usageService.canScan();
      case QuotaType.premium:
        allowed = await usageService.isPremium();
    }

    if (allowed) return true;

    // Blocked - trigger UI feedback
    HapticHelper.error();

    if (!context.mounted) return false;

    if (popOnBlock) {
      Navigator.of(context).pop();
    }

    if (authNotifier.isAnonymous) {
      unawaited(showAuthBottomSheet(context, onSuccess: onAuthSuccess));
    } else {
      unawaited(showPaywallScreen(context, onProceedWithLimited: onProceedWithLimited ?? () {}));
    }

    return false;
  }
}
