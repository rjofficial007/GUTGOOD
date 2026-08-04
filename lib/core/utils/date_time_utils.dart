import 'package:cloud_firestore/cloud_firestore.dart';

class DateTimeUtils {
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
}
