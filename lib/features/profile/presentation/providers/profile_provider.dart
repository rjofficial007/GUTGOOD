import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/firestore_service.dart';

class ProfileNotifier with ChangeNotifier {
  final AuthRepository _authRepository;
  final FirestoreService _firestoreService;
  final AppStateService _appStateService;

  UserProfile? _profile;
  bool _isLoading = false;
  String _quickInsight = "Log more meals to see patterns.";
  StreamSubscription<UserProfile?>? _profileSub;

  ProfileNotifier(this._authRepository, this._firestoreService, this._appStateService) {
    _initProfileStream();
    _appStateService.insightsData.addListener(_updateInsights);
    _appStateService.sessionReset.addListener(_onSessionReset);
  }

  void _initProfileStream() {
    _profileSub?.cancel();
    _profileSub = _firestoreService.getUserMetadataStream().listen((profile) {
      _profile = profile;
      _updateInsights();
      notifyListeners();
    }, onError: (e) => Log.e('ProfileNotifier: Stream error', error: e));
  }

  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  String get quickInsight => _quickInsight;

  @override
  void dispose() {
    _profileSub?.cancel();
    _appStateService.insightsData.removeListener(_updateInsights);
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onSessionReset() {
    _profile = null;
    _quickInsight = "Log more meals to see patterns.";
    _initProfileStream();
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

    final updatedProfile = _profile!.copyWith(cycleSyncEnabled: enabled, updatedAt: DateTime.now());

    await _firestoreService.updateUserProfile(updatedProfile);
    _profile = updatedProfile;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(File file) async {
    _isLoading = true;
    notifyListeners();

    await _firestoreService.uploadProfilePicture(file);
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
      Log.w('ProfileNotifier: Cannot complete onboarding, no active user session.');
      _isLoading = false;
      notifyListeners();
      return;
    }

    final String uid = currentUser.uid;
    final bool isAnonymous = currentUser.isAnonymous;
    final String? email = currentUser.email;
    final String? finalDisplayName = displayName ?? currentUser.displayName ?? _profile?.displayName;

    // 1. Update Firebase Auth if name was provided during onboarding
    if (displayName != null && displayName.isNotEmpty && displayName != currentUser.displayName) {
      try {
        await _authRepository.updateDisplayName(displayName);
      } catch (e) {
        Log.e('Error updating display name during onboarding: $e');
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
      Log.e('Error updating display name: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _initProfileStream();
  }
}
