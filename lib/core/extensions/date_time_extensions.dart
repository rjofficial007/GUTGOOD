import 'package:intl/intl.dart';

/// Extension on [DateTime] providing relative day formatting and date helpers.
extension DateTimeFormattingX on DateTime {
  /// Returns a user-friendly relative day string like "Today", "Yesterday", "Monday", or "MMM d, yyyy".
  String toRelativeDayString() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(year, month, day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7 && diff > 0) return DateFormat('EEEE').format(this);
    return DateFormat('MMM d, yyyy').format(this);
  }

  /// Returns true if two DateTime objects fall on the exact same calendar day.
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
}
