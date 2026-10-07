import 'package:equatable/equatable.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
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
    this.journalEntryId,
    required this.symptom,
    this.severity,
    this.notes,
    this.mood,
    this.sleep,
    this.lastMealFirestoreId,
    this.foodName,
    this.imageUrl,
    this.source,
    this.provenance,
    required this.createdAt,
    this.occurredAt,
    this.occurredAtProvenance,
    this.schemaVersion = AiVersions.schemaVersion,
    this.promptVersion,
    this.model,
  });

  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];
    final rawProvenance = map['provenance']?.toString().trim();
    // P1-2: the AI's `time` estimate becomes a provenance-tagged occurrence,
    // never the ordering clock (createdAt below is log time only).
    final (occurredAt, occurredAtProvenance) = DateTimeUtils.occurredAtFromMap(map);

    var symptomName = map['symptom']?.toString() ?? map['name']?.toString() ?? map['feeling']?.toString() ?? map['title']?.toString() ?? map['type']?.toString();

    if (symptomName == null || symptomName.trim().isEmpty || symptomName == 'Unknown') {
      if (map['mood'] != null && map['mood'].toString().isNotEmpty) {
        symptomName = map['mood'].toString();
      } else {
        symptomName = 'Unknown';
      }
    }

    symptomName = symptomName.trim();

    final parsedImageUrl =
        ModelUtils.parseString(map['imageUrl']) ??
        ModelUtils.parseString(map['userImageUrl']) ??
        ModelUtils.parseString(map['photoUrl']) ??
        ModelUtils.parseString(map['foodImageUrl']) ??
        ModelUtils.parseString(map['scanImage']);

    return SymptomLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      chatMessageId: map['chatMessageId'] as String?,
      journalEntryId: map['journalEntryId']?.toString() ?? map['journalId']?.toString(),
      symptom: symptomName,
      severity: int.tryParse(map['severity']?.toString() ?? ''),
      notes: map['notes']?.toString(),
      mood: map['mood']?.toString(),
      sleep: map['sleep']?.toString(),
      lastMealFirestoreId: map['lastMealFirestoreId']?.toString() ?? map['lastMealId']?.toString() ?? map['journalEntryId']?.toString(),
      foodName: map['foodName']?.toString() ?? map['lastMealName']?.toString() ?? map['mealName']?.toString() ?? map['food']?.toString(),
      imageUrl: parsedImageUrl,
      source: map['source']?.toString(),
      provenance: rawProvenance == null || rawProvenance.isEmpty ? null : rawProvenance,
      createdAt: DateTimeUtils.parse(map['createdAt']),
      occurredAt: occurredAt,
      occurredAtProvenance: occurredAtProvenance,
      schemaVersion: (map['v'] as num?)?.toInt() ?? AiVersions.schemaVersion,
      promptVersion: (map['promptVersion'] as num?)?.toInt(),
      model: map['model'] as String?,
    );
  }

  /// Legacy local persistence key, retained for backward-compatible records.
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Identifier of the user who owns this log.
  final String? uid;

  /// The localId of the ChatMessage that triggered this log via passive logging.
  final String? chatMessageId;

  /// Stable id shared by all typed records belonging to one journal event.
  /// A symptom uses the linked meal/journal document id when available.
  final String? journalEntryId;

  /// The primary symptom reported (e.g., "Bloating", "Gas", "Fatigue").
  final String symptom;

  /// Severity of the symptom on a scale of 1 to 10.
  final int? severity;

  /// Optional free-form user notes.
  final String? notes;

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

  /// How this record was detected ([RecordProvenance]). `keyword_fallback`
  /// records are excluded from pattern corroboration. Null on legacy docs
  /// (treated as confirmed — provenance can't be reconstructed retroactively).
  final String? provenance;

  /// Log time: when this record was written. The ordering/filtering clock for
  /// queries and pagination. Never an AI estimate (those live in [occurredAt]).
  final DateTime createdAt;

  /// Event time: when the symptom actually occurred, when known. Null means
  /// unknown — display and correlation fall back to [createdAt] via [eventTime].
  final DateTime? occurredAt;

  /// Where [occurredAt] came from ([OccurrenceProvenance]). Null when unknown.
  final String? occurredAtProvenance;

  /// Durable-doc schema version (§17), stamped as `v`.
  final int schemaVersion;

  /// J-4 §17: chat-prompt version that extracted this symptom. Null on legacy docs.
  final int? promptVersion;

  /// J-4 §17: serving model id echoed by the proxy for this extraction.
  final String? model;

  /// Best-known moment of the symptom for display + correlation windows.
  DateTime get eventTime => occurredAt ?? createdAt;

  SymptomLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    String? chatMessageId,
    String? journalEntryId,
    String? symptom,
    int? severity,
    String? notes,
    String? mood,
    String? sleep,
    String? lastMealFirestoreId,
    String? foodName,
    String? imageUrl,
    String? source,
    String? provenance,
    DateTime? createdAt,
    DateTime? occurredAt,
    String? occurredAtProvenance,
    int? schemaVersion,
    int? promptVersion,
    String? model,
    // Explicit clears: plain `?? this.x` params cannot null a field, but the
    // validator must be able to void insane numbers (out-of-range severity).
    bool clearSeverity = false,
  }) => SymptomLog(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    chatMessageId: chatMessageId ?? this.chatMessageId,
    journalEntryId: journalEntryId ?? this.journalEntryId,
    symptom: symptom ?? this.symptom,
    severity: clearSeverity ? null : (severity ?? this.severity),
    notes: notes ?? this.notes,
    mood: mood ?? this.mood,
    sleep: sleep ?? this.sleep,
    lastMealFirestoreId: lastMealFirestoreId ?? this.lastMealFirestoreId,
    foodName: foodName ?? this.foodName,
    imageUrl: imageUrl ?? this.imageUrl,
    source: source ?? this.source,
    provenance: provenance ?? this.provenance,
    createdAt: createdAt ?? this.createdAt,
    occurredAt: occurredAt ?? this.occurredAt,
    occurredAtProvenance: occurredAtProvenance ?? this.occurredAtProvenance,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    promptVersion: promptVersion ?? this.promptVersion,
    model: model ?? this.model,
  );

  Map<String, dynamic> toMap() => {
    'v': schemaVersion,
    'promptVersion': promptVersion,
    'model': model,
    'firestoreId': firestoreId,
    'chatMessageId': chatMessageId,
    'journalEntryId': journalEntryId,
    'symptom': symptom,
    if (severity != null) 'severity': severity,
    if (notes != null) 'notes': notes,
    if (mood != null) 'mood': mood,
    if (sleep != null) 'sleep': sleep,
    'lastMealFirestoreId': lastMealFirestoreId,
    'foodName': foodName,
    'imageUrl': imageUrl,
    'source': source,
    if (provenance?.trim().isNotEmpty == true) 'provenance': provenance,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
    if (occurredAt != null) 'occurredAt': DateTimeUtils.toNullableTimestamp(occurredAt),
    if (occurredAtProvenance != null) 'occurredAtProvenance': occurredAtProvenance,
  };

  /// JSON-safe variant of [toMap] for navigation extras (route codec):
  /// identical but with ISO-8601 dates instead of Firestore Timestamps.
  /// Round-trips through [SymptomLog.fromMap].
  Map<String, dynamic> toJsonMap() => {
    ...toMap(),
    'createdAt': createdAt.toIso8601String(),
    if (occurredAt != null) 'occurredAt': occurredAt!.toIso8601String(),
  };

  /// Optimized map for AI context (no Firestore [Timestamp] objects).
  Map<String, dynamic> toAiMap() => {
    'symptom': symptom,
    if (severity != null) 'severity': severity,
    if (notes != null) 'notes': notes,
    if (mood != null) 'mood': mood,
    if (sleep != null) 'sleep': sleep,
    'lastMealFirestoreId': lastMealFirestoreId,
    'foodName': foodName,
    'imageUrl': imageUrl,
    'source': source,
    'createdAt': createdAt.toIso8601String(),
    if (provenance?.trim().isNotEmpty == true) 'provenance': provenance,
    if (occurredAt != null) 'occurredAt': occurredAt!.toIso8601String(),
    if (occurredAtProvenance != null) 'occurredAtProvenance': occurredAtProvenance,
  };

  @override
  List<Object?> get props => [id, firestoreId, chatMessageId, journalEntryId, symptom, severity, createdAt, occurredAt, occurredAtProvenance, lastMealFirestoreId, foodName, imageUrl, provenance];
}
