/// Pure utility class for calculating streak progression.
class StreakCalculator {
  /// Calculates current streak based on the last logged activity date.
  /// If logged today or yesterday, existing streak is preserved/incremented.
  /// If more than 1 day has elapsed, streak resets to 0.
  static int calculateCurrentStreak({
    required DateTime? lastLogDate,
    required int existingStreak,
  }) {
    if (lastLogDate == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(lastLogDate.year, lastLogDate.month, lastLogDate.day);
    final diffDays = today.difference(logDay).inDays;

    if (diffDays == 0 || diffDays == 1) {
      return existingStreak > 0 ? existingStreak : 1;
    }
    return 0;
  }
}
