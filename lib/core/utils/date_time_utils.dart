import 'package:cloud_firestore/cloud_firestore.dart';

class DateTimeUtils {
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
}
