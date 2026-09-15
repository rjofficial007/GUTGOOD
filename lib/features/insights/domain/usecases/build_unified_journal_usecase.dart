import 'package:gutgood/core/models/models.dart';

/// Interleaves different event types (Meals, Symptoms, Scans) into a
/// chronologically sorted text journal for AI analysis.
class BuildUnifiedJournalUseCase {
  const BuildUnifiedJournalUseCase();

  String execute({required List<MealLog> meals, required List<SymptomLog> symptoms, required List<ScanResult> scans}) {
    final allEvents = <_JournalEvent>[];

    for (final m in meals) {
      allEvents.add(_JournalEvent(createdAt: m.createdAt, text: 'ATE: ${m.mealType ?? 'Meal'} (${m.items.join(', ')})'));
    }

    for (final s in symptoms) {
      allEvents.add(
        _JournalEvent(
          createdAt: s.createdAt,
          text: 'FEELING: ${s.symptom} (Severity: ${s.severity}${s.energyLevel != null ? ', Energy: ${s.energyLevel}' : ''}${s.sleep != null ? ', Sleep: ${s.sleep}' : ''})',
        ),
      );
    }

    for (final s in scans) {
      allEvents.add(_JournalEvent(createdAt: s.createdAt, text: 'SCANNED: ${s.productName} (${s.brand}) - Score: ${s.score}'));
    }

    // Sort everything by createdAt (Oldest -> Newest)
    allEvents.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return allEvents
        .map((e) {
          final timeStr = e.createdAt.toIso8601String().substring(0, 16).replaceAll('T', ' ');
          return '- $timeStr: ${e.text}';
        })
        .join('\n');
  }
}

class _JournalEvent {
  const _JournalEvent({required this.createdAt, required this.text});
  final DateTime createdAt;
  final String text;
}
