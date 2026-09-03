import 'package:equatable/equatable.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Represents a physical or emotional symptom reported by the user.
///
/// Symptom logs are the primary data source for the [PatternEngineService] to
/// find correlations between food intake and body reactions.
class SymptomLog extends Equatable {
  const SymptomLog({
    this.id,
    this.firestoreId,
    this.uid,
    this.chatMessageId,
    required this.symptom,
    this.severity,
    this.notes,
    this.energyLevel,
    this.mood,
    this.sleep,
    this.lastMealFirestoreId,
    this.foodName,
    this.imageUrl,
    this.source,
    required this.createdAt,
  });

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];

    var symptomName = map['symptom']?.toString() ??
        map['name']?.toString() ??
        map['feeling']?.toString() ??
        map['title']?.toString() ??
        map['type']?.toString();

    var energyLevel = int.tryParse(map['energyLevel']?.toString() ?? '');

    if (symptomName == null || symptomName.trim().isEmpty || symptomName == 'Unknown') {
      if (energyLevel != null && energyLevel >= 7) {
        symptomName = 'Energetic';
      } else if (energyLevel != null && energyLevel <= 3) {
        symptomName = 'Low Energy';
      } else if (map['mood'] != null && map['mood'].toString().isNotEmpty) {
        symptomName = map['mood'].toString();
      } else {
        symptomName = 'Energetic';
      }
    }

    symptomName = symptomName.trim();

    // Auto-infer energy level if not set
    if (energyLevel == null) {
      final lower = symptomName.toLowerCase();
      if (lower.contains('energetic') || lower.contains('high energy') || lower.contains('vitality') || lower.contains('focused')) {
        energyLevel = 8;
      } else if (lower.contains('tired') || lower.contains('fatigue') || lower.contains('low energy') || lower.contains('sluggish')) {
        energyLevel = 2;
      }
    }

    final parsedImageUrl = ModelUtils.parseString(map['imageUrl']) ??
        ModelUtils.parseString(map['userImageUrl']) ??
        ModelUtils.parseString(map['photoUrl']) ??
        ModelUtils.parseString(map['foodImageUrl']) ??
        ModelUtils.parseString(map['scanImage']);

    return SymptomLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      chatMessageId: map['chatMessageId'] as String?,
      symptom: symptomName,
      severity: int.tryParse(map['severity']?.toString() ?? ''),
      notes: map['notes']?.toString(),
      energyLevel: energyLevel,
      mood: map['mood']?.toString(),
      sleep: map['sleep']?.toString(),
      lastMealFirestoreId: map['lastMealFirestoreId']?.toString() ?? map['lastMealId']?.toString(),
      foodName: map['foodName']?.toString() ?? map['lastMealName']?.toString() ?? map['mealName']?.toString() ?? map['food']?.toString(),
      imageUrl: parsedImageUrl,
      source: map['source']?.toString(),
      createdAt: DateTimeUtils.parse(map['createdAt'] ?? map['time']),
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

  /// Name of the food associated with this reaction/symptom.
  final String? foodName;

  /// Image URL of the scanned or uploaded food photo.
  final String? imageUrl;

  /// Origin of the log entry ('chat', 'manual').
  final String? source;

  /// Exact timestamp of record creation.
  final DateTime createdAt;

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
    String? foodName,
    String? imageUrl,
    String? source,
    DateTime? createdAt,
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
    foodName: foodName ?? this.foodName,
    imageUrl: imageUrl ?? this.imageUrl,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
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
    'foodName': foodName,
    'imageUrl': imageUrl,
    'source': source,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
  };

  /// Optimized map for AI context (no Firestore [Timestamp] objects).
  Map<String, dynamic> toAiMap() => {
    'symptom': symptom,
    'severity': severity,
    'notes': notes,
    'energyLevel': energyLevel,
    'mood': mood,
    'sleep': sleep,
    'lastMealFirestoreId': lastMealFirestoreId,
    'foodName': foodName,
    'imageUrl': imageUrl,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, firestoreId, chatMessageId, symptom, severity, createdAt, energyLevel, lastMealFirestoreId, foodName, imageUrl];
}
