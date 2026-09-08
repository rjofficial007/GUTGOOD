import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/scan_insight.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/utils/model_utils.dart';

void main() {
  group('ScanInsight parsing', () {
    test('parses severity and derives ranked concerns (top 3, strongest first)', () {
      final insight = ScanInsight.fromMap({
        'summary': 'A decent snack held back by sodium.',
        'positives': [
          {'title': 'High fibre', 'detail': '6 g per serving'},
        ],
        'concerns': [
          {'title': 'Sodium', 'detail': 'High for a snack', 'severity': 'higher'},
          {'title': 'Trace colouring', 'detail': 'Amount is negligible', 'severity': 'minor'},
          {'title': 'Added sugar', 'detail': 'Moderate', 'severity': 'moderate'},
          {'title': 'Fourth item', 'detail': 'Should be dropped from the top 3', 'severity': 'minor'},
        ],
        'warnings': ['Contains milk'],
      });

      expect(insight.concerns.length, 4);
      final ranked = insight.rankedConcerns;
      expect(ranked.length, 3, reason: 'The UI must never show more than three concerns at once.');
      expect(ranked.first.title, 'Sodium');
      expect(ranked.first.severity, ConcernSeverity.higher);
      expect(ranked[1].severity, ConcernSeverity.moderate, reason: 'Ordering must be strongest-first, not model-output order.');
      expect(ranked.map((c) => c.title), isNot(contains('Fourth item')));
      expect(insight.warnings, ['Contains milk']);
    });

    test('unknown severity falls back to moderate rather than alarming', () {
      final insight = ScanInsight.fromMap({
        'concerns': [
          {'title': 'Mystery', 'severity': 'catastrophic'},
        ],
      });
      expect(insight.concerns.single.severity, ConcernSeverity.moderate);
    });

    test('empty payload yields an empty insight, not nulls', () {
      final insight = ScanInsight.fromMap(null);
      expect(insight.isEmpty, isTrue);
      expect(insight.rankedConcerns, isEmpty);
    });
  });

  group('ScanResult.insight', () {
    test('round-trips through toMap/fromMap and is part of equality', () {
      final scan = ScanResult(
        productName: 'Test Bar',
        brand: 'GutGood',
        score: 61,
        impact: '',
        impactType: ImpactType.neutral,
        createdAt: DateTime(2026, 9, 8),
        insight: ScanInsight(
          summary: 'Balanced, with a sodium caveat.',
          scoreExplanation: 'Score 61 — good fiber help the score, while high sodium bring it down.',
          scoreFactors: const [ScoreFactor(label: 'Fiber 6g / 100g', delta: 5, phrase: 'good fiber')],
          concerns: const [InsightConcern(title: 'Sodium', severity: ConcernSeverity.important)],
        ),
      );

      final revived = ScanResult.fromMap(scan.toMap());
      expect(revived.insight, isNotNull);
      expect(revived.insight!.summary, scan.insight!.summary);
      expect(revived.insight!.scoreFactors.single.delta, 5);
      expect(revived.insight!.concerns.single.severity, ConcernSeverity.important);
      // NOTE: full ScanResult equality is intentionally not asserted — when a
      // map has no `rawData`, ScanResult.fromMap stores the whole map there
      // (pre-existing behaviour), so a toMap→fromMap round-trip always gains it.
      expect(revived.insight, equals(scan.insight), reason: 'insight must survive persistence and be comparable');
    });

    test('factorsSumTo detects breakdowns saved under the old 50-baseline engine', () {
      final contributions = ScanInsight(
        scoreFactors: [
          const ScoreFactor(label: 'Nutrition', delta: 32, phrase: 'a Nutri-Score of C'),
          const ScoreFactor(label: 'Additives', delta: 20, phrase: 'additives'),
          const ScoreFactor(label: 'Organic', delta: 0, phrase: 'organic'),
        ],
      );
      expect(contributions.factorsSumTo(52), isTrue);

      // Old convention: score = 50 + Σdelta, so the rows don't reconcile.
      final legacy = ScanInsight(
        scoreFactors: [
          const ScoreFactor(label: 'Nutri-Score A', delta: 25, phrase: 'an excellent Nutri-Score of A'),
          const ScoreFactor(label: 'NOVA 4', delta: -10, phrase: 'ultra-processing'),
        ],
      );
      expect(legacy.factorsSumTo(65), isFalse, reason: '50 + 15 = 65, but the rows only show +15.');
      expect(const ScanInsight().factorsSumTo(50), isFalse, reason: 'No factors means nothing to reconcile.');
    });

    test('scans without an insight stay null (backwards compatible)', () {
      final scan = ScanResult(productName: 'Legacy', brand: 'GutGood', score: 50, impact: '', impactType: ImpactType.neutral, createdAt: DateTime(2026, 1, 1));
      expect(ScanResult.fromMap(scan.toMap()).insight, isNull);
    });
  });
}
