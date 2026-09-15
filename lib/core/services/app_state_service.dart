import 'package:flutter/material.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';

abstract class AppStateService {
  ValueNotifier<bool> get chatUpdated;
  ValueNotifier<bool> get savedFoodsUpdated;
  ValueNotifier<bool> get profileUpdated;
  ValueNotifier<bool> get sessionReset;
  ValueNotifier<AIInsight?> get insightsData;
  ValueNotifier<String?> get emailLinkError;
  ValueNotifier<String?> get pendingEmailLink;
  ValueNotifier<Map<String, String>?> get pendingMergeConflict;
  ValueNotifier<bool> get isMigrating;
  ValueNotifier<bool> get isVerifyingAuth;
  ValueNotifier<bool> get isLoggingOut;
  ValueNotifier<bool> get isRestoringPurchases;

  void notifyChatUpdated();
  void notifySavedFoodsUpdated();
  void notifyProfileUpdated();
  void setInsightsData(AIInsight? data);
  void setEmailLinkError(String? error);
  void setPendingEmailLink(String? link);
  void setPendingMergeConflict(Map<String, String>? conflict);
  void setMigrating(bool value);
  void setVerifyingAuth(bool value);
  void setLoggingOut(bool value);
  void setRestoringPurchases(bool value);
  void resetSession();

  /// 🟢 NEW: Ensures only one merge conflict prompt is shown at a time.
  bool claimMergePrompt();
  void releaseMergePrompt();
}

class AppStateServiceImpl implements AppStateService {
  bool _mergePromptShowing = false;

  @override
  final ValueNotifier<bool> chatUpdated = ValueNotifier(false);
  @override
  final ValueNotifier<bool> savedFoodsUpdated = ValueNotifier(false);
  @override
  final ValueNotifier<bool> profileUpdated = ValueNotifier(false);
  @override
  final ValueNotifier<bool> sessionReset = ValueNotifier(false);
  @override
  final ValueNotifier<AIInsight?> insightsData = ValueNotifier(null);
  @override
  final ValueNotifier<String?> emailLinkError = ValueNotifier(null);
  @override
  final ValueNotifier<String?> pendingEmailLink = ValueNotifier(null);
  @override
  final ValueNotifier<Map<String, String>?> pendingMergeConflict = ValueNotifier(null);
  @override
  final ValueNotifier<bool> isMigrating = ValueNotifier(false);
  @override
  final ValueNotifier<bool> isVerifyingAuth = ValueNotifier(false);
  @override
  final ValueNotifier<bool> isLoggingOut = ValueNotifier(false);
  @override
  final ValueNotifier<bool> isRestoringPurchases = ValueNotifier(false);

  @override
  void notifyChatUpdated() => chatUpdated.value = !chatUpdated.value;
  @override
  void notifySavedFoodsUpdated() => savedFoodsUpdated.value = !savedFoodsUpdated.value;
  @override
  void notifyProfileUpdated() => profileUpdated.value = !profileUpdated.value;
  @override
  void setInsightsData(AIInsight? data) => insightsData.value = data;
  @override
  void setEmailLinkError(String? error) => emailLinkError.value = error;
  @override
  void setPendingEmailLink(String? link) => pendingEmailLink.value = link;
  @override
  void setPendingMergeConflict(Map<String, String>? conflict) => pendingMergeConflict.value = conflict;
  @override
  void setMigrating(bool value) => isMigrating.value = value;
  @override
  void setVerifyingAuth(bool value) => isVerifyingAuth.value = value;
  @override
  void setLoggingOut(bool value) => isLoggingOut.value = value;
  @override
  void setRestoringPurchases(bool value) => isRestoringPurchases.value = value;

  @override
  void resetSession() {
    insightsData.value = null;
    sessionReset.value = !sessionReset.value;
  }

  @override
  bool claimMergePrompt() {
    if (_mergePromptShowing) return false;
    _mergePromptShowing = true;
    return true;
  }

  @override
  void releaseMergePrompt() {
    _mergePromptShowing = false;
  }
}
