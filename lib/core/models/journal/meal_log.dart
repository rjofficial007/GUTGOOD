import 'package:equatable/equatable.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
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
    this.chatMessageId,
    required this.items,
    this.notes,
    this.mealType,
    this.photoUrl,
    this.analysisResult,
    this.source,
    this.foodTags = const [],
    required this.createdAt,
    this.occurredAt,
    this.occurredAtProvenance,
    this.schemaVersion = AiVersions.schemaVersion,
    this.promptVersion,
    this.model,
  });

  factory MealLog.fromMap(Map<String, dynamic> map) {
    final rawId = map['id'] ?? map['firestoreId'];
    // P1-2: the AI's `time` estimate becomes a provenance-tagged occurrence,
    // never the ordering clock (createdAt below is log time only).
    final (occurredAt, occurredAtProvenance) = DateTimeUtils.occurredAtFromMap(map);

    final rawItems = map['items'];
    var items = <String>[];
    if (rawItems is List) {
      items = rawItems
          .map((e) {
            if (e is String) return e;
            if (e is Map) return (e['name'] ?? e['title'] ?? '').toString();
            return e.toString();
          })
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      items = ModelUtils.parseList<String>(rawItems);
    }

    return MealLog(
      id: rawId is int ? rawId : null,
      firestoreId: rawId is String ? rawId : null,
      uid: map['uid'] as String?,
      chatMessageId: map['chatMessageId'] as String?,
      items: items,
      notes: map['notes'],
      mealType: map['mealType'],
      photoUrl: map['photoUrl'],
      analysisResult: map['analysisResult'],
      source: map['source'],
      foodTags: ModelUtils.parseList<String>(map['foodTags']),
      createdAt: DateTimeUtils.parse(map['createdAt']),
      occurredAt: occurredAt,
      occurredAtProvenance: occurredAtProvenance,
      schemaVersion: (map['v'] as num?)?.toInt() ?? AiVersions.schemaVersion,
      promptVersion: (map['promptVersion'] as num?)?.toInt(),
      model: map['model'] as String?,
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

  /// Log time: when this record was written. The ordering/filtering clock for
  /// queries and pagination. Never an AI estimate (those live in [occurredAt]).
  final DateTime createdAt;

  /// Event time: when the meal was actually eaten, when known. Null means
  /// unknown — display and correlation fall back to [createdAt] via [eventTime].
  final DateTime? occurredAt;

  /// Where [occurredAt] came from ([OccurrenceProvenance]). Null when unknown.
  final String? occurredAtProvenance;

  /// Durable-doc schema version (§17), stamped as `v`.
  final int schemaVersion;

  /// J-4 §17: chat-prompt version that extracted this meal. Null on legacy docs.
  final int? promptVersion;

  /// J-4 §17: serving model id echoed by the proxy for this extraction.
  final String? model;

  /// Best-known moment of the meal for display + correlation windows.
  DateTime get eventTime => occurredAt ?? createdAt;

  MealLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    String? chatMessageId,
    List<String>? items,
    String? notes,
    String? mealType,
    String? photoUrl,
    String? analysisResult,
    String? source,
    List<String>? foodTags,
    DateTime? createdAt,
    DateTime? occurredAt,
    String? occurredAtProvenance,
    int? schemaVersion,
    int? promptVersion,
    String? model,
  }) => MealLog(
    id: id ?? this.id,
    firestoreId: firestoreId ?? this.firestoreId,
    uid: uid ?? this.uid,
    chatMessageId: chatMessageId ?? this.chatMessageId,
    items: items ?? this.items,
    notes: notes ?? this.notes,
    mealType: mealType ?? this.mealType,
    photoUrl: photoUrl ?? this.photoUrl,
    analysisResult: analysisResult ?? this.analysisResult,
    source: source ?? this.source,
    foodTags: foodTags ?? this.foodTags,
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
    'items': items,
    'notes': notes,
    'mealType': mealType,
    'photoUrl': photoUrl,
    'analysisResult': analysisResult,
    'source': source,
    'foodTags': foodTags,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
    'occurredAt': DateTimeUtils.toNullableTimestamp(occurredAt),
    'occurredAtProvenance': occurredAtProvenance,
  };

  /// Optimized map for AI context (no Firestore [Timestamp] objects).
  Map<String, dynamic> toAiMap() => {
    'items': items,
    'notes': notes,
    'mealType': mealType,
    'photoUrl': photoUrl,
    'analysisResult': analysisResult,
    'source': source,
    'foodTags': foodTags,
    'createdAt': createdAt.toIso8601String(),
    if (occurredAt != null) 'occurredAt': occurredAt!.toIso8601String(),
    if (occurredAtProvenance != null) 'occurredAtProvenance': occurredAtProvenance,
  };

  @override
  List<Object?> get props => [id, firestoreId, chatMessageId, items, createdAt, occurredAt, occurredAtProvenance, source];
}
