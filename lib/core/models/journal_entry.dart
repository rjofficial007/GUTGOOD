import 'package:equatable/equatable.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

enum JournalEntryType { scan, meal, symptom }

/// Unified entry for the journal timeline.
class JournalEntry extends Equatable {
  const JournalEntry({required this.id, required this.type, required this.createdAt, this.scan, this.meal, this.symptom});

  final String id;
  final JournalEntryType type;
  final DateTime createdAt;
  final ScanResult? scan;
  final MealLog? meal;
  final SymptomLog? symptom;

  @override
  List<Object?> get props => [id, type, createdAt, scan, meal, symptom];
}
