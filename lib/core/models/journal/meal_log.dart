import 'package:equatable/equatable.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
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
    this.journalEntryId,
    this.scanId,
    this.scanCategory,
    this.scanConfidence,
    this.scanVerdict,
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
      journalEntryId: map['journalEntryId']?.toString() ?? map['journalId']?.toString(),
      scanId: map['scanId']?.toString(),
      scanCategory: map['scanCategory']?.toString(),
      scanConfidence: _parseScanConfidence(map['scanConfidence']),
      scanVerdict: map['scanVerdict']?.toString(),
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

  /// Legacy local persistence key, retained for backward-compatible records.
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Identifier of the user who owns this log.
  final String? uid;

  /// The localId of the ChatMessage that triggered this log via passive logging.
  final String? chatMessageId;

  /// Stable id shared by all typed records belonging to one journal event.
  /// For a meal record this is normally the meal document id itself.
  final String? journalEntryId;

  /// Originating scan id when this meal was created from a scan. This lets
  /// readers avoid counting the scan twice (scan_history + journal_logs).
  final String? scanId;

  /// Original scan classification retained for evidence-quality decisions.
  final String? scanCategory;

  /// AI confidence attached to the originating scan, when reported.
  final double? scanConfidence;

  /// AI verdict attached to the originating scan, when reported.
  final String? scanVerdict;

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

  /// True when this meal is the journal projection of [candidateScanId].
  ///
  /// The aliases cover current records and the stable IDs used by legacy
  /// projections, so Insights and journal views cannot drift into different
  /// deduplication rules.
  bool representsScanId(String? candidateScanId) {
    final id = candidateScanId?.trim();
    if (id == null || id.isEmpty) return false;
    return scanId == id || chatMessageId == id || firestoreId == id || firestoreId == '${id}_meal' || journalEntryId == id || journalEntryId == '${id}_meal';
  }

  static double? _parseScanConfidence(Object? raw) {
    final parsed = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
    if (parsed == null || parsed.isNaN || parsed < 0 || parsed > 1) return null;
    return parsed;
  }

  MealLog copyWith({
    int? id,
    String? firestoreId,
    String? uid,
    String? chatMessageId,
    String? journalEntryId,
    String? scanId,
    String? scanCategory,
    double? scanConfidence,
    String? scanVerdict,
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
    journalEntryId: journalEntryId ?? this.journalEntryId,
    scanId: scanId ?? this.scanId,
    scanCategory: scanCategory ?? this.scanCategory,
    scanConfidence: scanConfidence ?? this.scanConfidence,
    scanVerdict: scanVerdict ?? this.scanVerdict,
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
    'journalEntryId': journalEntryId,
    'scanId': scanId,
    if (scanCategory != null) 'scanCategory': scanCategory,
    if (scanConfidence != null) 'scanConfidence': scanConfidence,
    if (scanVerdict != null) 'scanVerdict': scanVerdict,
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
  List<Object?> get props => [id, firestoreId, chatMessageId, journalEntryId, scanId, scanCategory, scanConfidence, scanVerdict, items, createdAt, occurredAt, occurredAtProvenance, source];
}
