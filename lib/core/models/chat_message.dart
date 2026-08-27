import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Why a message turn failed, used to render the correct recovery UI.
enum ChatErrorKind { none, connection, quota, upload }

/// Represents a single turn in the conversational AI chat interface.
///
/// Messages can contain rich data including images, AI scan results,
/// and product swaps. The [role] field identifies the sender (user vs. assistant).
class ChatMessage extends Equatable {
  const ChatMessage({
    this.id,
    this.firestoreId,
    required this.localId,
    this.uid,
    required this.role,
    required this.text,
    String? imageUrl,
    this.imageUrls = const [],
    this.localImages,
    this.scanData,
    this.mealLogs = const [],
    this.symptomLogs = const [],
    this.swapData,
    this.analysisResult,
    this.isSwap = false,
    this.feedback,
    this.isSending = false,
    this.sendFailed = false,
    this.errorKind = ChatErrorKind.none,
    this.source,
    this.foodMentions = const [],
    this.symptomMentions = const [],
    this.isHidden = false,
    required this.createdAt,
  }) : _imageUrl = imageUrl;

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    final rawLocalId = map['id'];
    final rawCloudId = map['firestoreId'];

    // Multi-image field with legacy single-image fallback.
    final imageUrls = ModelUtils.parseList<String>(map['imageUrls']);
    final legacyImageUrl = map['imageUrl'] as String?;
    final resolvedImageUrls = imageUrls.isNotEmpty ? imageUrls : (legacyImageUrl != null && legacyImageUrl.isNotEmpty ? [legacyImageUrl] : const <String>[]);

    final analysisResult = ModelUtils.parseNestedModel<AiAnalysisResult>(map['analysisResult'], AiAnalysisResult.fromMap);

    return ChatMessage(
      id: rawLocalId is int ? rawLocalId : null,
      firestoreId: rawCloudId is String ? rawCloudId : null,
      localId: map['localId'] as String? ?? '',
      uid: map['uid'] as String?,
      role: map['role'] ?? 'user',
      text: map['text'] ?? '',
      imageUrl: resolvedImageUrls.isNotEmpty ? resolvedImageUrls.first : legacyImageUrl,
      imageUrls: resolvedImageUrls,
      // 🚀 Professional Parsing: Support both embedded data and reference previews
      scanData:
          analysisResult?.scan ??
          ModelUtils.parseNestedModel<ScanResult>(map['scanData'], ScanResult.fromMap) ??
          (map['scanPreview'] != null ? ScanResult.fromMap({...map['scanPreview'], 'scanId': map['scanId']}) : null),
      mealLogs: analysisResult?.meal != null
          ? [analysisResult!.meal!]
          : (ModelUtils.parseModelList<MealLog>(map['mealLogs'], MealLog.fromMap).isNotEmpty ? ModelUtils.parseModelList<MealLog>(map['mealLogs'], MealLog.fromMap) : []),
      symptomLogs: analysisResult != null && analysisResult.symptoms.isNotEmpty ? analysisResult.symptoms : ModelUtils.parseModelList<SymptomLog>(map['symptomLogs'], SymptomLog.fromMap),
      swapData: analysisResult != null && analysisResult.swaps.isNotEmpty ? analysisResult.swaps : ModelUtils.parseModelList<ProductSwap>(map['swapData'], ProductSwap.fromMap),
      analysisResult: analysisResult,
      isSwap: ModelUtils.parseBool(map['isSwap']),
      feedback: map['feedback'],
      source: map['source'],
      foodMentions: ModelUtils.parseList<String>(map['foodMentions']),
      symptomMentions: ModelUtils.parseList<String>(map['symptomMentions']),
      isHidden: ModelUtils.parseBool(map['isHidden'] ?? false),
      createdAt: DateTimeUtils.parse(map['createdAt'] ?? map['time']),
    );
  }

  /// Local SQLite primary key (legacy, kept for backward compatibility).
  final int? id;

  /// Cloud Firestore unique identifier.
  final String? firestoreId;

  /// Client-side unique identifier for stable deduplication.
  final String localId;

  /// Identifier of the user who owns this message.
  final String? uid;

  /// The sender's role: 'user' or 'ai'.
  final String role;

  /// The actual text content (supports Markdown formatting).
  final String text;

  /// Legacy single-image storage. Prefer [imageUrls].
  final String? _imageUrl;

  /// Public URL of the first image (kept for backward compatibility with
  /// older documents and widgets). Always mirrors `imageUrls.first` when
  /// images exist.
  String? get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : _imageUrl;

  /// Public URLs of ALL images attached to this message (ChatGPT-style
  /// multi-image turns). Order matches the order the user attached them.
  final List<String> imageUrls;

  /// Raw bytes for local image previews before upload completes.
  final List<Uint8List>? localImages;

  /// Rich scan result data if this message represents a product analysis.
  final ScanResult? scanData;

  /// Structured meal logs extracted from this message.
  final List<MealLog> mealLogs;

  /// Structured symptom logs extracted from this message.
  final List<SymptomLog> symptomLogs;

  /// List of healthier alternatives if suggested by the AI.
  final List<ProductSwap>? swapData;

  /// Unified structured AI analysis result.
  final AiAnalysisResult? analysisResult;

  /// Whether this message includes gut-friendly product swaps.
  final bool isSwap;

  /// User feedback on AI response accuracy: 'helpful' or 'not_helpful'.
  final String? feedback;

  /// Whether the message is currently in the process of being sent.
  final bool isSending;

  /// Whether sending this message (or its attachments) failed; the UI shows
  /// a retry affordance until the user retries or dismisses it.
  final bool sendFailed;

  /// Categorized failure for AI turns (never persisted to Firestore).
  final ChatErrorKind errorKind;

  /// Source identifier (e.g., 'chat', 'scanner', 'manual').
  final String? source;

  /// Structured list of food items identified in this message.
  final List<String> foodMentions;

  /// Structured list of physical symptoms identified in this message.
  final List<String> symptomMentions;

  /// Whether this message is hidden from the UI (but still used for context).
  final bool isHidden;

  /// The exact time the message was created or received.
  final DateTime createdAt;

  /// Back-compat getter for single-image widgets.
  Uint8List? get localImageBytes => (localImages != null && localImages!.isNotEmpty) ? localImages!.first : null;

  ChatMessage copyWith({
    int? id,
    String? firestoreId,
    String? localId,
    String? uid,
    String? role,
    String? text,
    String? imageUrl,
    List<String>? imageUrls,
    List<Uint8List>? localImages,
    ScanResult? scanData,
    List<MealLog>? mealLogs,
    List<SymptomLog>? symptomLogs,
    List<ProductSwap>? swapData,
    AiAnalysisResult? analysisResult,
    bool? isSwap,
    String? feedback,
    bool? isSending,
    bool? sendFailed,
    ChatErrorKind? errorKind,
    String? source,
    List<String>? foodMentions,
    List<String>? symptomMentions,
    bool? isHidden,
    DateTime? createdAt,
    bool clearLocalImages = false,
  }) {
    final nextImageUrls = imageUrls ?? this.imageUrls;
    return ChatMessage(
      id: id ?? this.id,
      firestoreId: firestoreId ?? this.firestoreId,
      localId: localId ?? this.localId,
      uid: uid ?? this.uid,
      role: role ?? this.role,
      text: text ?? this.text,
      imageUrl: imageUrl ?? (nextImageUrls.isNotEmpty ? nextImageUrls.first : this.imageUrl),
      imageUrls: nextImageUrls,
      localImages: clearLocalImages ? null : (localImages ?? this.localImages),
      scanData: scanData ?? this.scanData,
      mealLogs: mealLogs ?? this.mealLogs,
      symptomLogs: symptomLogs ?? this.symptomLogs,
      swapData: swapData ?? this.swapData,
      analysisResult: analysisResult ?? this.analysisResult,
      isSwap: isSwap ?? this.isSwap,
      feedback: feedback ?? this.feedback,
      isSending: isSending ?? this.isSending,
      sendFailed: sendFailed ?? this.sendFailed,
      errorKind: errorKind ?? this.errorKind,
      source: source ?? this.source,
      foodMentions: foodMentions ?? this.foodMentions,
      symptomMentions: symptomMentions ?? this.symptomMentions,
      isHidden: isHidden ?? this.isHidden,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'firestoreId': firestoreId,
    'localId': localId,
    'uid': uid,
    'role': role,
    'text': text,
    'imageUrl': imageUrl,
    'imageUrls': imageUrls,
    // 🚀 Deduplication: Store IDs and minimal preview metadata only
    'scanId': scanData?.scanId,
    'scanPreview': scanData != null
        ? {
            'productName': scanData!.productName,
            'brand': scanData!.brand,
            'score': scanData!.score,
            'imageUrl': scanData!.imageUrl,
            'userImageUrl': scanData!.userImageUrl,
            'impactType': scanData!.impactType.name,
            'impact': scanData!.impact,
            'source': scanData!.source,
            'category': scanData!.category,
            'intent': scanData!.rawData?['intent'], // 🚀 Fixed: Include intent for smart routing
          }
        : null,
    'journalEntryIds': [...mealLogs.map((e) => e.firestoreId).whereType<String>(), ...symptomLogs.map((e) => e.firestoreId).whereType<String>()],
    'mealLogs': mealLogs.map((e) => e.toMap()).toList(),
    'symptomLogs': symptomLogs.map((e) => e.toMap()).toList(),
    'swapData': swapData?.map((e) => e.toMap()).toList(),
    'analysisResult': analysisResult?.toMap(),
    'isSwap': isSwap,
    'feedback': feedback,
    'source': source,
    'foodMentions': foodMentions,
    'symptomMentions': symptomMentions,
    'isHidden': isHidden,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
  };

  Map<String, String> toAiMap() {
    final role = this.role == 'user' ? 'user' : 'assistant';
    final buffer = StringBuffer(text);

    if (scanData != null) {
      buffer.write('\n\n[SCAN_CONTEXT]${ModelUtils.safeJsonEncode(scanData!.toAiMap())}[/SCAN_CONTEXT]');
    }

    if (mealLogs.isNotEmpty) {
      buffer.write('\n\n[MEAL_CONTEXT]${ModelUtils.safeJsonEncode({'items': mealLogs.map((e) => e.toAiMap()).toList()})}[/MEAL_CONTEXT]');
    }

    if (symptomLogs.isNotEmpty) {
      buffer.write('\n\n[SYMPTOM_CONTEXT]${ModelUtils.safeJsonEncode({'items': symptomLogs.map((e) => e.toAiMap()).toList()})}[/SYMPTOM_CONTEXT]');
    }

    if (swapData != null && swapData!.isNotEmpty) {
      buffer.write(
        '\n\n[SWAPS_CONTEXT]${ModelUtils.safeJsonEncode({
          'items': swapData!.map((e) => {'title': e.title, 'subtitle': e.subtitle}).toList(),
        })}[/SWAPS_CONTEXT]',
      );
    }

    return {'role': role, 'content': buffer.toString().trim()};
  }

  @override
  List<Object?> get props => [
    id,
    firestoreId,
    localId,
    role,
    text,
    imageUrl,
    imageUrls,
    scanData,
    mealLogs,
    symptomLogs,
    swapData,
    analysisResult,
    isSwap,
    feedback,
    isSending,
    sendFailed,
    errorKind,
    isHidden,
    createdAt,
  ];
}
