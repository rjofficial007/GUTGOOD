import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/analytics_service.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/crashlytics_service.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileNotifier with ChangeNotifier {
  ProfileNotifier(this._authRepository, this._firestoreService, this._appStateService, this._notificationService, this._analyticsService, this._crashlyticsService) {
    _initProfileStream();
    _appStateService.insightsData.addListener(_updateInsights);
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Reactive Data Loading: Restart stream whenever auth state changes (login/switch)
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initProfileStream();
      } else {
        _onSessionReset();
      }
    });
  }

  final AuthRepository _authRepository;
  final AuthFirestoreService _firestoreService;
  final AppStateService _appStateService;
  final NotificationService _notificationService;
  final AnalyticsService _analyticsService;
  final CrashlyticsService _crashlyticsService;

  UserProfile? _profile;
  int? _previousStreak;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _showStreakCelebration = false;
  bool _pendingStreakCelebration = false; // 🟢 Track if a celebration is queued
  String _quickInsight = 'Log more meals to see patterns.';
  StreamSubscription<UserProfile?>? _profileSub;

  void _initProfileStream() {
    _profileSub?.cancel();
    _isInitialized = false; // Reset initialization state during user switch
    _profile = null; // Clear stale profile data
    notifyListeners(); // 🟢 Notify immediately so UI can show fallback auth data

    _profileSub = _firestoreService.getUserMetadataStream().listen((profile) {
      _isInitialized = true;
      if (profile != null) {
        // Detect streak increment
        if (_previousStreak != null && profile.streak > _previousStreak!) {
          _pendingStreakCelebration = true; // 🟢 Queue it, don't show yet
          unawaited(_analyticsService.logEvent(name: 'streak_incremented', parameters: {'streak': profile.streak}));
          AppLogger.info('ProfileNotifier: Streak incremented! ${profile.streak}');
        }
        _previousStreak = profile.streak;

        // Manage Streak Saver Notification
        final today = DateTime.now().toIso8601String().split('T')[0];
        if (profile.lastActivityDate == today) {
          _notificationService.cancel(NotificationIds.streakSaver);
        } else {
          _notificationService.scheduleStreakSaverReminder(profile.streak);
        }
      }

      _profile = profile;
      _updateInsights();
      notifyListeners();
    }, onError: (e) => AppLogger.error('ProfileNotifier: Stream error', error: e));
  }

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get showStreakCelebration => _showStreakCelebration;
  String get quickInsight => _quickInsight;

  void dismissStreakCelebration() {
    _showStreakCelebration = false;
    _pendingStreakCelebration = false;
    notifyListeners();
  }

  void triggerPendingCelebration() {
    if (_pendingStreakCelebration && !_showStreakCelebration) {
      _showStreakCelebration = true;
      _pendingStreakCelebration = false;
      notifyListeners();
      AppLogger.info('ProfileNotifier: Pending streak celebration triggered.');
    }
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _appStateService.insightsData.removeListener(_updateInsights);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onSessionReset() {
    _profile = null;
    _previousStreak = null;
    _showStreakCelebration = false;
    _isInitialized = false;
    _quickInsight = 'Log more meals to see patterns.';
    _profileSub?.cancel();
    notifyListeners();
  }

  void _updateInsights() {
    final insights = _appStateService.insightsData.value;
    if (insights != null && insights.topInsight != null) {
      _quickInsight = insights.topInsight!.description;
    }
    notifyListeners();
  }

  Future<void> updateCycleSync(bool enabled) async {
    if (_profile == null) return;

    await _analyticsService.logEvent(name: 'cycle_sync_toggled', parameters: {'enabled': enabled});
    final updatedProfile = _profile!.copyWith(cycleSyncEnabled: enabled, updatedAt: DateTime.now());

    await _firestoreService.updateUserProfile(updatedProfile);
    _profile = updatedProfile;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.uploadProfilePicture(file);
      await _analyticsService.logEvent(name: 'profile_picture_updated');
    } catch (e, st) {
      AppLogger.error('Error uploading profile picture: $e');
      await _crashlyticsService.recordError(e, st, reason: 'Profile picture upload failed');
    }
    // Profile will be updated via stream

    _isLoading = false;
    notifyListeners();
  }

  Future<void> completeOnboarding({
    required List<String> goals,
    required List<String> sensitivities,
    required List<String> lifestyle,
    required bool cycleSyncEnabled,
    String? cyclePhase,
    String? displayName,
  }) async {
    _isLoading = true;
    notifyListeners();

    final currentUser = sl<FirebaseAuth>().currentUser;
    if (currentUser == null) {
      AppLogger.warning('ProfileNotifier: Cannot complete onboarding, no active user session.');
      _isLoading = false;
      notifyListeners();
      return;
    }

    final uid = currentUser.uid;
    final isAnonymous = currentUser.isAnonymous;
    final email = currentUser.email;
    final finalDisplayName = displayName ?? currentUser.displayName ?? _profile?.displayName;

    // 1. Update Firebase Auth if name was provided during onboarding
    if (displayName != null && displayName.isNotEmpty && displayName != currentUser.displayName) {
      try {
        await _authRepository.updateDisplayName(displayName);
      } catch (e) {
        AppLogger.error('Error updating display name during onboarding: $e');
      }
    }

    final updatedProfile = (_profile ?? UserProfile(uid: uid, updatedAt: DateTime.now(), createdAt: DateTime.now())).copyWith(
      uid: uid,
      onboarded: true,
      isAnonymous: isAnonymous,
      email: email,
      displayName: finalDisplayName,
      goals: goals,
      sensitivities: sensitivities,
      lifestyle: lifestyle,
      cycleSyncEnabled: cycleSyncEnabled,
      cyclePhase: cyclePhase,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updateUserProfile(updatedProfile);
    // _profile will be updated via stream

    await _analyticsService.logEvent(
      name: 'onboarding_completed',
      parameters: {'goals_count': goals.length, 'sensitivities_count': sensitivities.length, 'lifestyle_count': lifestyle.length, 'cycle_sync_enabled': cycleSyncEnabled},
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarded', true);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateUserProfile(UserProfile profile) async {
    await _firestoreService.updateUserProfile(profile);
  }

  Future<void> updateDisplayName(String name) async {
    if (_profile == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Update Firebase Auth
      await _authRepository.updateDisplayName(name);

      // 2. Update Firestore
      final updatedProfile = _profile!.copyWith(displayName: name, updatedAt: DateTime.now());
      await _firestoreService.updateUserProfile(updatedProfile);
    } catch (e) {
      AppLogger.error('Error updating display name: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initProfileStream();
  }
}
