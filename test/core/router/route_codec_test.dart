import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_list_args.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';
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
    test('passes through null and primitives', () {
      expect(roundTrip(null), isNull);
      expect(roundTrip('chat'), 'chat');
      expect(roundTrip(['a', 'b']), ['a', 'b']);
    });

    test('round-trips AIInsight with JSON-safe dates', () {
      final out =
          roundTrip(
                AIInsight.fromMap(const {
                  'gutScore': 80,
                  'topInsight': {'title': 'T', 'description': 'D', 'type': 'Pattern'},
                }),
              )
              as AIInsight;
      expect(out.gutScore, 80);
      expect(out.topInsight?.title, 'T');
    });

    test('round-trips BodyPattern', () {
      final out = roundTrip(BodyPattern.fromMap(const {'type': 'Bloating', 'trigger': 'Milk'})) as BodyPattern;
      expect(out.trigger, 'Milk');
    });

    test('round-trips ScanResult', () {
      final out = roundTrip(ScanResult.fromMap(const {'productName': 'Oats', 'brand': 'Quaker', 'category': 'food', 'score': 90, 'impact': 'Great'})) as ScanResult;
      expect(out.productName, 'Oats');
    });

    test('round-trips ScanResultArgs', () {
      final out = roundTrip(ScanResultArgs(scanData: ScanResult.fromMap(const {'productName': 'Oats', 'brand': 'Q', 'score': 90, 'impact': 'Ok'}), heroTag: 'h')) as ScanResultArgs;
      expect(out.scanData.productName, 'Oats');
      expect(out.heroTag, 'h');
    });

    test('round-trips InsightSummary', () {
      const summary = InsightSummary(title: 'T', description: 'D', type: 'Pattern', involvedFoods: ['Milk'], frequency: 3);
      final out = roundTrip(summary) as InsightSummary;
      expect(out.title, 'T');
      expect(out.involvedFoods, ['Milk']);
      expect(out.frequency, 3);
    });

    test('round-trips SymptomLog with JSON-safe dates', () {
      final log = SymptomLog(symptom: 'Bloating', severity: 3, createdAt: DateTime.utc(2026, 1, 2, 3, 4, 5));
      final out = roundTrip(log) as SymptomLog;
      expect(out.symptom, 'Bloating');
      expect(out.severity, 3);
      expect(out.createdAt, DateTime.utc(2026, 1, 2, 3, 4, 5));
    });

    test('round-trips AdditiveConcern', () {
      const concern = AdditiveConcern(code: 'E621', name: 'MSG', whatItIs: 'w', whyUsed: 'u', level: AdditiveConcernLevel.moderate, whyFlagged: 'f', explanation: 'e');
      final out = roundTrip(concern) as AdditiveConcern;
      expect(out.code, 'E621');
      expect(out.level, AdditiveConcernLevel.moderate);
    });

    test('round-trips ScanListDetailArgs', () {
      final out = roundTrip(ScanListDetailArgs(kind: ScanListKind.additives, scan: ScanResult.fromMap(const {'productName': 'Oats', 'brand': 'Q', 'score': 90, 'impact': 'Ok'}))) as ScanListDetailArgs;
      expect(out.kind, ScanListKind.additives);
      expect(out.scan.productName, 'Oats');
    });

    test('round-trips ProductSwap', () {
      const swap = ProductSwap(title: 'Oat Drink', subtitle: 'Oatly', imageKeyword: 'oat', tag: 'BETTER', barcode: '123', nutriscore: 'a');
      final out = roundTrip(swap) as ProductSwap;
      expect(out.title, 'Oat Drink');
      expect(out.barcode, '123');
    });
  });
}
