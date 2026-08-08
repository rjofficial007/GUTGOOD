import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents a recorded food consumption event.
///
/// Meal logs track what was eaten and when, optionally including photos
/// and AI-generated nutrient analysis.
class MealLog extends Equatable {
  const MealLog({
    this.id,
    this.firestoreId,
    this.uid,
    required this.items,
    this.notes,
    this.mealType,
    this.photoUrl,
    this.analysisResult,
    this.source,
    this.foodTags = const [],
    required this.time,
  });

  factory MealLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];
    return MealLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      items: ModelUtils.parseList<String>(map['items']),
      notes: map['notes'],
      mealType: map['mealType'],
      photoUrl: map['photoUrl'],
      analysisResult: map['analysisResult'],
      source: map['source'],
      foodTags: ModelUtils.parseList<String>(map['foodTags']),
      time: DateTimeUtils.parse(map['time']),
    );
  }

  /// Local SQLite primary key.
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Identifier of the user who owns this log.
  final String? uid;

  /// List of specific items or dishes consumed.
  final List<String> items;

  /// Optional user notes regarding the meal (e.g., "Dining out").
  final String? notes;

  /// Category of the meal (e.g., 'breakfast', 'lunch', 'dinner', 'snack').
  final String? mealType;

  /// URL to the photo of the meal if captured.
  final String? photoUrl;

  /// Narrative summary of nutrient impact if processed by AI.
  final String? analysisResult;

  /// Origin of the log entry ('chat', 'scanner', 'manual').
  final String? source;

  /// Custom descriptive tags for the food (e.g., #highprotein).
  final List<String> foodTags;

  /// Exact timestamp of consumption.
  final DateTime time;

  MealLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    List<String>? items,
    String? notes,
    String? mealType,
    String? photoUrl,
    String? analysisResult,
    String? source,
    List<String>? foodTags,
    DateTime? time,
  }) => MealLog(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    items: items ?? this.items,
    notes: notes ?? this.notes,
    mealType: mealType ?? this.mealType,
    photoUrl: photoUrl ?? this.photoUrl,
    analysisResult: analysisResult ?? this.analysisResult,
    source: source ?? this.source,
    foodTags: foodTags ?? this.foodTags,
    time: time ?? this.time,
  );

  Map<String, dynamic> toMap() => {
    'firestoreId': firestoreId,
    'items': items,
    'notes': notes,
    'mealType': mealType,
    'photoUrl': photoUrl,
    'analysisResult': analysisResult,
    'source': source,
    'foodTags': foodTags,
    'time': time.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, firestoreId, items, time, source];
}
