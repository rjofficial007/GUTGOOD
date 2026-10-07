import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/product_details/presentation/widgets/scan_result_widgets.dart';

void main() {
  test('missing nutrient values do not create positive or watch claims', () {
    final scan = ScanResult(productName: 'Unknown food', brand: '', score: 50, impactType: ImpactType.neutral, impact: '', nutrients: const NutrientData(), createdAt: DateTime(2026, 10, 7));

    expect(ScanWorkingSection.hasData(scan), isFalse);
    expect(ScanWatchSection.hasData(scan), isFalse);
  });
}
