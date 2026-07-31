import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents the central user identity and health profile in GutGood.
///
/// This model synchronizes between Firebase Auth, Firestore, and Local SQLite.
/// It tracks personalization factors (goals, sensitivities, lifestyle) which
/// drive the AI insight generation engine.
class UserProfile extends Equatable {
  /// Unique identifier from Firebase Auth.
  final String uid;

  /// Whether the user has completed the onboarding flow.
  final bool onboarded;

  /// Whether the user has an active premium subscription.
  final bool isPremium;

  /// Whether the session is an anonymous guest session.
  final bool isAnonymous;

  /// The user's chosen display name or "Guest".
  final String? displayName;

  /// The user's authenticated email address.
  final String? email;

  /// URL to the user's profile picture in Firebase Storage.
  final String? photoUrl;

  /// The provider used for authentication (google.com, apple.com, password).
  final String? authProvider;

  /// List of health goals (e.g., "Better Energy", "Less Bloating").
  final List<String> goals;

  /// List of identified food sensitivities (e.g., "Dairy", "Gluten").
  final List<String> sensitivities;

  /// List of current lifestyle factors (e.g., "High Stress", "Gym").
  final List<String> lifestyle;

  /// Whether hormonal cycle synchronization is enabled (for female users).
  final bool cycleSyncEnabled;

  /// The current phase of the hormonal cycle if [cycleSyncEnabled] is true.
  final String? cyclePhase;

  /// User-defined notification settings.
  final Map<String, dynamic> notificationPreferences;

  /// Current aggregate gut health score (0-100).
  final int gutScore;

  /// Current daily check-in streak.
  final int streak;

  /// Subscription tier identifier.
  final String subscriptionStatus;

  /// Last local or remote modification timestamp.
  final DateTime updatedAt;

  /// Account creation timestamp.
  final DateTime createdAt;

  const UserProfile({
    required this.uid,
    this.onboarded = false,
    this.isPremium = false,
    this.isAnonymous = true,
    this.displayName,
    this.email,
    this.photoUrl,
    this.authProvider,
    this.goals = const [],
    this.sensitivities = const [],
    this.lifestyle = const [],
    this.cycleSyncEnabled = false,
    this.cyclePhase,
    this.notificationPreferences = const {},
    this.gutScore = 0,
    this.streak = 0,
    this.subscriptionStatus = 'free',
    required this.updatedAt,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? uid,
    bool? onboarded,
    bool? isPremium,
    bool? isAnonymous,
    String? displayName,
    String? email,
    String? photoUrl,
    String? authProvider,
    List<String>? goals,
    List<String>? sensitivities,
    List<String>? lifestyle,
    bool? cycleSyncEnabled,
    String? cyclePhase,
    Map<String, dynamic>? notificationPreferences,
    int? gutScore,
    int? streak,
    String? subscriptionStatus,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      onboarded: onboarded ?? this.onboarded,
      isPremium: isPremium ?? this.isPremium,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      authProvider: authProvider ?? this.authProvider,
      goals: goals ?? this.goals,
      sensitivities: sensitivities ?? this.sensitivities,
      lifestyle: lifestyle ?? this.lifestyle,
      cycleSyncEnabled: cycleSyncEnabled ?? this.cycleSyncEnabled,
      cyclePhase: cyclePhase ?? this.cyclePhase,
      notificationPreferences: notificationPreferences ?? this.notificationPreferences,
      gutScore: gutScore ?? this.gutScore,
      streak: streak ?? this.streak,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, {String? uid}) {
    return UserProfile(
      uid: uid ?? map['uid'] ?? '',
      onboarded: ModelUtils.parseBool(map['onboarded']),
      isPremium: ModelUtils.parseBool(map['isPremium']),
      isAnonymous: ModelUtils.parseBool(map['isAnonymous']),
      displayName: map['displayName'],
      email: map['email'],
      photoUrl: map['photoUrl'],
      authProvider: map['authProvider'],
      goals: map['goals'] is String ? List<String>.from(jsonDecode(map['goals'])) : List<String>.from(map['goals'] ?? []),
      sensitivities: map['sensitivities'] is String ? List<String>.from(jsonDecode(map['sensitivities'])) : List<String>.from(map['sensitivities'] ?? []),
      lifestyle: map['lifestyle'] is String ? List<String>.from(jsonDecode(map['lifestyle'])) : List<String>.from(map['lifestyle'] ?? []),
      cycleSyncEnabled: ModelUtils.parseBool(map['cycleSyncEnabled']),
      cyclePhase: map['cyclePhase'],
      notificationPreferences: map['notificationPreferences'] is String ? jsonDecode(map['notificationPreferences']) : Map<String, dynamic>.from(map['notificationPreferences'] ?? {}),
      gutScore: map['gutScore'] ?? 0,
      streak: map['streak'] ?? 0,
      subscriptionStatus: map['subscriptionStatus'] ?? 'free',
      updatedAt: DateTimeUtils.parse(map['updatedAt']),
      createdAt: DateTimeUtils.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'onboarded': onboarded,
      'isPremium': isPremium,
      'isAnonymous': isAnonymous,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'authProvider': authProvider,
      'goals': goals,
      'sensitivities': sensitivities,
      'lifestyle': lifestyle,
      'cycleSyncEnabled': cycleSyncEnabled,
      'cyclePhase': cyclePhase,
      'notificationPreferences': notificationPreferences,
      'gutScore': gutScore,
      'streak': streak,
      'subscriptionStatus': subscriptionStatus,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [uid, onboarded, isPremium, isAnonymous, goals, sensitivities, lifestyle, gutScore, streak];
}
