import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/router/route_codec.dart';

/// go_router serializes `extra` through [RouteCodec] — every extra type used
/// in app_router must survive encode → json → decode, or navigation throws
/// "Converting object to an encodable object failed". The [jsonEncode] in the
/// helper below IS the assertion: any leaked Timestamp/model crashes like prod.
void main() {
  const codec = RouteCodec();

  Object? roundTrip(Object? extra) {
    final json = jsonEncode(codec.encode(extra));
    return codec.decode(jsonDecode(json));
  }

  group('RouteCodec', () {
    test('Round-trip primitive (String)', () {
      const input = 'hello';
      final output = roundTrip(input);
      expect(output, input);
    });

    test('Round-trip primitive (Map)', () {
      final input = {'key': 'value', 'nested': 123};
      final output = roundTrip(input);
      expect(output, input);
    });

    test('Round-trip ScanResult', () {
      final input = ScanResult(
        productName: 'Yogurt',
        brand: 'Brand',
        category: 'food',
        barcode: '12345',
        score: 85,
        impactType: ImpactType.positive,
        impact: 'High protein',
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final output = roundTrip(input) as ScanResult;
      expect(output.productName, input.productName);
      expect(output.createdAt, input.createdAt);
    });

    test('Round-trip ScanResultArgs', () {
      final input = ScanResultArgs(
        scanData: ScanResult(productName: 'Yogurt', brand: 'Brand', category: 'food', barcode: '123', score: 50, impactType: ImpactType.neutral, impact: 'ok', createdAt: DateTime.now().toUtc()),
      );
      final output = roundTrip(input) as ScanResultArgs;
      expect(output.scanData.productName, 'Yogurt');
    });

    test('Round-trip AIInsight', () {
      final input = AIInsight(
        gutScore: 80,
        updatedAt: DateTime.now().toUtc(),
        topInsight: const InsightSummary(title: 'Great job', description: 'Keep eating fiber', type: 'Summary'),
      );
      final output = roundTrip(input) as AIInsight;
      expect(output.gutScore, 80);
      expect(output.topInsight?.title, 'Great job');
    });

    test('Round-trip SymptomLog', () {
      final input = SymptomLog(symptom: 'Bloating', severity: 2, createdAt: DateTime.now().toUtc());
      final output = roundTrip(input) as SymptomLog;
      expect(output.symptom, 'Bloating');
      expect(output.severity, 2);
    });

    test('Round-trip AdditiveConcern', () {
      const input = AdditiveConcern(code: 'E123', name: 'Color', whatItIs: 'A color', whyUsed: 'To look good', level: AdditiveConcernLevel.higher, whyFlagged: 'Signal', explanation: 'Avoid it');
      final output = roundTrip(input) as AdditiveConcern;
      expect(output.code, 'E123');
      expect(output.level, AdditiveConcernLevel.higher);
    });

    test('Round-trip ScanListDetailArgs', () {
      final input = ScanListDetailArgs(
        kind: ScanListKind.additives,
        scan: ScanResult(productName: 'Yogurt', brand: 'Brand', category: 'food', barcode: '123', score: 50, impactType: ImpactType.neutral, impact: 'ok', createdAt: DateTime.now().toUtc()),
      );
      final output = roundTrip(input) as ScanListDetailArgs;
      expect(output.kind, ScanListKind.additives);
      expect(output.scan.productName, 'Yogurt');
    });

    test('Round-trip ProductSwap', () {
      const input = ProductSwap(title: 'Better Yogurt', subtitle: 'Less sugar', imageKeyword: 'yogurt', tag: 'GOOD');
      final output = roundTrip(input) as ProductSwap;
      expect(output.title, 'Better Yogurt');
      expect(output.tag, 'GOOD');
    });
  });
}
