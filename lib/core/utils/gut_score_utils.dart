class GutScoreUtils {
  /// Calculates a deterministic Gut Score (0-100) based on Nutri-Score and NOVA group.
  /// This formula is the single source of truth for the app and should be
  /// communicated to the AI to ensure consistency.
  static int calculateGutScore(String? nutriscore, int? novaGroup) {
    int base = 50;

    if (nutriscore != null) {
      switch (nutriscore.toLowerCase()) {
        case 'a':
          base = 90;
          break;
        case 'b':
          base = 75;
          break;
        case 'c':
          base = 50;
          break;
        case 'd':
          base = 30;
          break;
        case 'e':
          base = 15;
          break;
      }
    }

    if (novaGroup != null) {
      if (novaGroup == 4) base -= 20;
      if (novaGroup == 1) base += 10;
    }

    return base.clamp(0, 100);
  }

  static String getStatus(int score) {
    if (score >= 80) return 'Great Choice';
    if (score >= 50) return 'Moderate Choice';
    return 'Avoid if Possible';
  }

  static String getStatusColor(int score) {
    if (score >= 80) return 'green';
    if (score >= 50) return 'orange';
    return 'red';
  }
}
