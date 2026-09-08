import 'package:gutgood/core/utils/date_time_utils.dart';

/// A user's report about an AI-generated response.
///
/// Google Play requires apps that generate AI content to provide "in-app user
/// reporting or flagging features that allow users to report or flag offensive
/// content to developers **without needing to exit the app**", and to use those
/// reports to inform filtering and moderation.
///
/// The existing thumbs-up/thumbs-down ([ChatMessage.feedback]) does NOT satisfy
/// this: it measures satisfaction, not safety, and carries no reason or detail
/// a moderator could act on. This is the missing half.
class AiReport {
  const AiReport({
    required this.reason,
    required this.messageExcerpt,
    this.details = '',
    this.messageId,
    this.reportedBy = '',
    this.createdAt,
  });

  /// Stamped at write time rather than construction time, which also keeps the
  /// constructor `const`.
  final DateTime? createdAt;

  /// The single source of truth for report reasons.
  ///
  /// These exact strings are validated in `firestore.rules`. A test asserts the
  /// two stay in sync, because a mismatch would make reports fail silently in
  /// production — the worst possible failure mode for a compliance feature.
  static const List<String> allowedReasons = [
    'inaccurate',
    'unsafe',
    'offensive',
    'off_topic',
    'other',
  ];

  /// Max lengths, mirrored by `firestore.rules`.
  static const int maxDetailsLength = 1000;
  static const int maxExcerptLength = 2000;

  final String reason;

  /// The text being reported, truncated. Enough for a moderator to act on
  /// without storing the user's whole conversation in the report.
  final String messageExcerpt;

  /// Optional free text from the user.
  final String details;

  final String? messageId;
  final String reportedBy;

  bool get isValidReason => allowedReasons.contains(reason);

  /// Truncates defensively so the write can never be rejected for size.
  static String sanitize(String value, int max) => value.length <= max ? value : value.substring(0, max);

  static String excerptOf(String text) => sanitize(text.trim(), maxExcerptLength);

  AiReport copyWith({String? reportedBy, String? reason, String? messageExcerpt, String? details}) => AiReport(
    reason: reason ?? this.reason,
    messageExcerpt: messageExcerpt ?? this.messageExcerpt,
    details: details ?? this.details,
    messageId: messageId,
    reportedBy: reportedBy ?? this.reportedBy,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'reason': reason,
    'messageExcerpt': sanitize(messageExcerpt, maxExcerptLength),
    'details': sanitize(details, maxDetailsLength),
    if (messageId != null) 'messageId': messageId,
    'reportedBy': reportedBy,
    'createdAt': DateTimeUtils.toTimestamp(createdAt ?? DateTime.now()),
  };

  @override
  String toString() => 'AiReport($reason, ${messageExcerpt.length} chars)';
}
