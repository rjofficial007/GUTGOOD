import 'package:flutter/material.dart';
import 'package:gutgood/core/theme/app_palette.dart';

/// Single source of truth for GutGood score band classifications.
/// Score bands: ≥90 Excellent · ≥70 Great · ≥50 Good · ≥30 Fair · below 30 Trigger
enum GutScoreBand {
  excellent(minScore: 90, label: 'Excellent', color: AppPalette.green),
  great(minScore: 70, label: 'Great', color: AppPalette.green500),
  good(minScore: 50, label: 'Good', color: AppPalette.orange),
  fair(minScore: 30, label: 'Fair', color: AppPalette.orange),
  trigger(minScore: 0, label: 'Trigger', color: AppPalette.red);

  const GutScoreBand({required this.minScore, required this.label, required this.color});

  final int minScore;
  final String label;
  final Color color;

  static GutScoreBand fromScore(int score) {
    if (score >= 90) return GutScoreBand.excellent;
    if (score >= 70) return GutScoreBand.great;
    if (score >= 50) return GutScoreBand.good;
    if (score >= 30) return GutScoreBand.fair;
    return GutScoreBand.trigger;
  }
}

class GutScoreUtils {
  // Product scoring lives in `yuka_score.dart` (Yuka-style 60/30/10).
  // This file keeps only the band/label helpers.

  static String getStatus(int score) => GutScoreBand.fromScore(score).label;

  static Color getScoreColor(int score) => GutScoreBand.fromScore(score).color;

  static String getStatusColor(int score) {
    final band = GutScoreBand.fromScore(score);
    if (band == GutScoreBand.excellent || band == GutScoreBand.great) return 'green';
    if (band == GutScoreBand.good || band == GutScoreBand.fair) return 'orange';
    return 'red';
  }
}
