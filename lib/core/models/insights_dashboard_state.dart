import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/health_alert.dart';

/// A consolidated state object representing all reactive data needed for the 
/// Insights dashboard.
class InsightsDashboardState extends Equatable {
  const InsightsDashboardState({
    this.latestInsight,
    this.patterns = const [],
    this.alerts = const [],
    this.totalMeals = 0,
    this.totalSymptoms = 0,
    this.totalScans = 0,
  });

  final AIInsight? latestInsight;
  final List<BodyPattern> patterns;
  final List<HealthAlert> alerts;
  final int totalMeals;
  final int totalSymptoms;
  final int totalScans;

  InsightsDashboardState copyWith({
    AIInsight? latestInsight,
    List<BodyPattern>? patterns,
    List<HealthAlert>? alerts,
    int? totalMeals,
    int? totalSymptoms,
    int? totalScans,
  }) {
    return InsightsDashboardState(
      latestInsight: latestInsight ?? this.latestInsight,
      patterns: patterns ?? this.patterns,
      alerts: alerts ?? this.alerts,
      totalMeals: totalMeals ?? this.totalMeals,
      totalSymptoms: totalSymptoms ?? this.totalSymptoms,
      totalScans: totalScans ?? this.totalScans,
    );
  }

  @override
  List<Object?> get props => [
    latestInsight,
    patterns,
    alerts,
    totalMeals,
    totalSymptoms,
    totalScans,
  ];
}
