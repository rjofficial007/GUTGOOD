import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';

/// Represents a physical or emotional symptom reported by the user.
/// 
/// Symptom logs are the primary data source for the [PatternEngineService] to
/// find correlations between food intake and body reactions.
class SymptomLog extends Equatable {
  /// Local SQLite primary key.
  final int? id;
  
  /// Cloud Firestore unique identifier.
  final String? firestoreId;
  
  /// Identifier of the user who owns this log.
  final String? uid;
  
  /// The primary symptom reported (e.g., "Bloating", "Gas", "Fatigue").
  final String symptom;
  
  /// Severity of the symptom on a scale of 1 to 10.
  final int? severity;
  
  /// Optional free-form user notes.
  final String? notes;
  
  /// Subjective energy level at the time of reporting (1-10).
  final int? energyLevel;
  
  /// Current mood identifier.
  final String? mood;
  
  /// Quality of sleep identifier.
  final String? sleep;
  
  /// Reference to the most recent [MealLog] within a 4-hour window.
  final int? lastMealId;
  
  /// Origin of the log entry ('chat', 'manual').
  final String? source;
  
  /// Exact timestamp when the symptom occurred.
  final DateTime time;

  const SymptomLog({
    this.id,
    this.firestoreId,
    this.uid,
    required this.symptom,
    this.severity,
    this.notes,
    this.energyLevel,
    this.mood,
    this.sleep,
    this.lastMealId,
    this.source,
    required this.time,
  });

  SymptomLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    String? symptom,
    int? severity,
    String? notes,
    int? energyLevel,
    String? mood,
    String? sleep,
    int? lastMealId,
    String? source,
    DateTime? time,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      uid: uid ?? this.uid,
      symptom: symptom ?? this.symptom,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      sleep: sleep ?? this.sleep,
      lastMealId: lastMealId ?? this.lastMealId,
      source: source ?? this.source,
      time: time ?? this.time,
    );
  }

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];
    return SymptomLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      symptom: map['symptom'] ?? 'Unknown',
      severity: (map['severity'] as num?)?.toInt(),
      notes: map['notes'],
      energyLevel: (map['energyLevel'] as num?)?.toInt(),
      mood: map['mood'],
      sleep: map['sleep'],
      lastMealId: (map['lastMealId'] as num?)?.toInt(),
      source: map['source'],
      time: DateTimeUtils.parse(map['time']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firestoreId': firestoreId,
      'symptom': symptom,
      'severity': severity,
      'notes': notes,
      'energyLevel': energyLevel,
      'mood': mood,
      'sleep': sleep,
      'lastMealId': lastMealId,
      'source': source,
      'time': time.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, firestoreId, symptom, severity, time, energyLevel];
}
