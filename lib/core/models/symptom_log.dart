import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';

/// Represents a physical or emotional symptom reported by the user.
///
/// Symptom logs are the primary data source for the [PatternEngineService] to
/// find correlations between food intake and body reactions.
class SymptomLog extends Equatable {
  const SymptomLog({this.id, this.firestoreId, this.uid, this.chatMessageId, required this.symptom, this.severity, this.notes, this.energyLevel, this.mood, this.sleep, this.lastMealFirestoreId, this.source, required this.time});

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];
    return SymptomLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      chatMessageId: map['chatMessageId'] as String?,
      symptom: map['symptom'] ?? 'Unknown',
      severity: int.tryParse(map['severity']?.toString() ?? ''),
      notes: map['notes'],
      energyLevel: int.tryParse(map['energyLevel']?.toString() ?? ''),
      mood: map['mood'],
      sleep: map['sleep'],
      lastMealFirestoreId: map['lastMealFirestoreId']?.toString() ?? map['lastMealId']?.toString(),
      source: map['source'],
      time: DateTimeUtils.parse(map['time']),
    );
  }

  /// Local SQLite primary key.
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Identifier of the user who owns this log.
  final String? uid;

  /// The localId of the ChatMessage that triggered this log via passive logging.
  final String? chatMessageId;

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
  final String? lastMealFirestoreId;

  /// Origin of the log entry ('chat', 'manual').
  final String? source;

  /// Exact timestamp when the symptom occurred.
  final DateTime time;

  SymptomLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    String? chatMessageId,
    String? symptom,
    int? severity,
    String? notes,
    int? energyLevel,
    String? mood,
    String? sleep,
    String? lastMealFirestoreId,
    String? source,
    DateTime? time,
  }) => SymptomLog(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    chatMessageId: chatMessageId ?? this.chatMessageId,
    symptom: symptom ?? this.symptom,
    severity: severity ?? this.severity,
    notes: notes ?? this.notes,
    energyLevel: energyLevel ?? this.energyLevel,
    mood: mood ?? this.mood,
    sleep: sleep ?? this.sleep,
    lastMealFirestoreId: lastMealFirestoreId ?? this.lastMealFirestoreId,
    source: source ?? this.source,
    time: time ?? this.time,
  );

  Map<String, dynamic> toMap() => {
    'firestoreId': firestoreId,
    'chatMessageId': chatMessageId,
    'symptom': symptom,
    'severity': severity,
    'notes': notes,
    'energyLevel': energyLevel,
    'mood': mood,
    'sleep': sleep,
    'lastMealFirestoreId': lastMealFirestoreId,
    'source': source,
    'time': time.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, firestoreId, chatMessageId, symptom, severity, time, energyLevel, lastMealFirestoreId];
}
