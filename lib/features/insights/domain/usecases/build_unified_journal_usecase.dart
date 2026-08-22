import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

/// Interleaves different event types (Meals, Symptoms, Scans) into a 
/// chronologically sorted text journal for AI analysis.
class BuildUnifiedJournalUseCase {
  const BuildUnifiedJournalUseCase();

  String execute({
    required List<MealLog> meals,
    required List<SymptomLog> symptoms,
    required List<ScanResult> scans,
  }) {
    final allEvents = <_JournalEvent>[];

    for (final m in meals) {
      allEvents.add(_JournalEvent(
        time: m.time,
        text: 'ATE: ${m.mealType ?? 'Meal'} (${m.items.join(', ')})',
      ));
    }

    for (final s in symptoms) {
      allEvents.add(_JournalEvent(
        time: s.time,
        text: 'FEELING: ${s.symptom} (Severity: ${s.severity}${s.energyLevel != null ? ', Energy: ${s.energyLevel}' : ''}${s.sleep != null ? ', Sleep: ${s.sleep}' : ''})',
      ));
    }

    for (final s in scans) {
      if (s.time != null) {
        allEvents.add(_JournalEvent(
          time: s.time!,
          text: 'SCANNED: ${s.productName} (${s.brand}) - Score: ${s.score}',
        ));
      }
    }

    // Sort everything by time (Oldest -> Newest)
    allEvents.sort((a, b) => a.time.compareTo(b.time));

    return allEvents.map((e) {
      final timeStr = e.time.toIso8601String().substring(0, 16).replaceAll('T', ' ');
      return '- $timeStr: ${e.text}';
    }).join('\n');
  }
}

class _JournalEvent {
  const _JournalEvent({required this.time, required this.text});
  final DateTime time;
  final String text;
}
