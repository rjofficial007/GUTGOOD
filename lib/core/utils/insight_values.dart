/// Values at the Insights boundary: missing and non-finite numbers are unknown,
/// while a measured zero remains a real value.
abstract final class InsightValues {
  static num? number(Object? value) {
    final parsed = value is num
        ? value
        : value is String
        ? num.tryParse(value.trim())
        : null;
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  static int? integer(Object? value) => number(value)?.toInt();

  static String text(Object? value, {String fallback = '—'}) {
    final result = value is String ? value.trim() : '';
    return result.isEmpty || const {'null', 'undefined', 'nan', 'infinity', 'n/a', 'not available'}.contains(result.toLowerCase()) || result == '—'
        ? fallback
        : result;
  }

  static List<double> scores(Iterable<num> values) => [
    for (final value in values)
      if (value.isFinite && value >= 0 && value <= 100) value.toDouble(),
  ];

  static bool isPositiveReaction(String text) {
    final lower = text.toLowerCase();
    final positiveKeywords = ['energetic', 'energy', 'refreshed', 'calm', 'good', 'great', 'boost', 'vitality', 'light', 'positive', 'steady', 'balanced', 'comfortable'];
    final negativeKeywords = [
      'bloating',
      'headache',
      'pain',
      'gas',
      'nausea',
      'cramping',
      'fatigue',
      'sluggish',
      'sleepy',
      'fulness',
      'fullness',
      'diarrhea',
      'constipation',
      'discomfort',
      'acid',
      'reflux',
      'heartburn',
      'indigestion',
      'heavy',
      'stuffed',
    ];

    for (final pos in positiveKeywords) {
      if (lower.contains(pos)) {
        var hasNegative = false;
        for (final neg in negativeKeywords) {
          if (lower.contains(neg)) {
            hasNegative = true;
            break;
          }
        }
        if (!hasNegative) return true;
      }
    }
    return false;
  }
}
