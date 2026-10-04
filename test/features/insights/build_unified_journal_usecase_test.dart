import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';

void main() {
  test('does not emit a second scan event when the scan has a meal projection', () {
    final now = DateTime.now();
    final scan = ScanResult(
      productName: 'Oats',
      brand: 'Brand',
      category: 'food',
      scanId: 'scan-1',
      score: 80,
      impactType: ImpactType.positive,
      impact: 'Good',
      createdAt: now,
    );
    final meal = MealLog(items: const ['Oats'], scanId: 'scan-1', journalEntryId: 'scan-1_meal', createdAt: now);

    const useCase = BuildUnifiedJournalUseCase();
    final journal = useCase.execute(meals: [meal], symptoms: const [], scans: [scan]);

    expect(journal, contains('ATE:'));
    expect(journal, isNot(contains('SCANNED:')));
  });

  test('keeps a legacy scan event when no meal projection exists', () {
    final scan = ScanResult(
      productName: 'Legacy Food',
      brand: 'Brand',
      category: 'food',
      scanId: 'legacy-scan',
      score: 70,
      impactType: ImpactType.neutral,
      impact: 'Neutral',
      createdAt: DateTime.now(),
    );

    const useCase = BuildUnifiedJournalUseCase();
    final journal = useCase.execute(meals: const [], symptoms: const [], scans: [scan]);

    expect(journal, contains('SCANNED: Legacy Food'));
  });
}
