/// Extension on [DateTime] providing relative day formatting and date helpers.
extension DateTimeFormattingX on DateTime {
  /// Returns true if two DateTime objects fall on the exact same calendar day.
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
}
