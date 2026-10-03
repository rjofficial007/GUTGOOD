import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';

class DateTimeUtils {
  /// Upper sanity bound for AI-estimated event times: 1h of future grace
  /// covers timezone edges; anything beyond is a model error, not dinner.
  static const Duration occurredAtFutureGrace = Duration(hours: 1);

  /// Lower sanity bound: estimates older than 30 days are stale context, not
  /// usable correlation input.
  static const Duration occurredAtMaxAge = Duration(days: 30);

  /// Resolves an event time + provenance from a raw AI/Firestore map (P1-2).
  /// An explicit stored `occurredAt` passes through verbatim (already vetted
  /// at creation); otherwise the AI's `time` field is adopted as an
  /// `ai_estimated` occurrence — unless insane (too far future/past) or
  /// unparseable, in which case unknown stays unknown (null, not `now()`).
  static (DateTime?, String?) occurredAtFromMap(Map<String, dynamic> map) {
    if (map['occurredAt'] != null) {
      return (tryParse(map['occurredAt']), map['occurredAtProvenance']?.toString());
    }
    final aiTime = tryParse(map['time']);
    if (aiTime == null) return (null, null);
    final now = DateTime.now();
    if (aiTime.isAfter(now.add(occurredAtFutureGrace)) || aiTime.isBefore(now.subtract(occurredAtMaxAge))) {
      return (null, null);
    }
    return (aiTime, OccurrenceProvenance.aiEstimated);
  }

  /// Robust parser that handles Firestore [Timestamp], ISO 8601 [String],
  /// unix [int], and existing [DateTime] objects.
  static DateTime parse(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    if (value is Timestamp) return value.toDate();

    if (value is String) {
      if (value.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now();
  }

  /// Nullable variant of [parse]: unparseable input (null, empty, garbage
  /// strings like the AI's "last night") yields null instead of `now()`.
  /// Used for event times ([occurredAt]), where "unknown" must stay unknown
  /// rather than masquerading as the current moment.
  static DateTime? tryParse(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      if (value.isEmpty) return null;
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    if (value is int) {
      try {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Parses a value and ensures the result is in UTC.
  static DateTime parseToUtc(dynamic value) {
    final dt = parse(value);
    return dt.isUtc ? dt : dt.toUtc();
  }

  /// Converts any supported date/time format into a Firestore [Timestamp].
  static Timestamp toTimestamp(dynamic value) {
    if (value is Timestamp) return value;
    return Timestamp.fromDate(parse(value));
  }

  /// Nullable variant of [toTimestamp] for optional event times.
  static Timestamp? toNullableTimestamp(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value;
    final parsed = tryParse(value);
    return parsed == null ? null : Timestamp.fromDate(parsed);
  }
}
