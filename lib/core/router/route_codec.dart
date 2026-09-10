import 'dart:convert';

import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_list_args.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/models/symptom_log.dart';

/// go_router `extra` codec: extras are serialized as JSON (state
/// restoration), so every non-primitive type passed as `state.extra` in
/// app_router MUST be registered here or navigation throws "Converting
/// object to an encodable object failed". Timestamp-bearing models use
/// their JSON-safe `toJsonMap`, never Firestore `toMap`.
class RouteCodec extends Codec<Object?, Object?> {
  const RouteCodec();

  @override
  Converter<Object?, Object?> get decoder => const _RouteDecoder();

  @override
  Converter<Object?, Object?> get encoder => const _RouteEncoder();
}

class _RouteEncoder extends Converter<Object?, Object?> {
  const _RouteEncoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is AIInsight) {
      return {'__type': 'AIInsight', 'data': input.toJsonMap()};
    }
    if (input is BodyPattern) {
      return {'__type': 'BodyPattern', 'data': input.toMap()};
    }
    if (input is ScanResult) {
      return {'__type': 'ScanResult', 'data': input.toMap()};
    }
    if (input is ScanResultArgs) {
      return {'__type': 'ScanResultArgs', 'data': input.toMap()};
    }
    if (input is InsightSummary) {
      return {'__type': 'InsightSummary', 'data': input.toMap()};
    }
    if (input is SymptomLog) {
      return {'__type': 'SymptomLog', 'data': input.toJsonMap()};
    }
    if (input is AdditiveConcern) {
      return {'__type': 'AdditiveConcern', 'data': input.toMap()};
    }
    if (input is ScanListDetailArgs) {
      return {'__type': 'ScanListDetailArgs', 'data': input.toMap()};
    }
    if (input is ProductSwap) {
      return {'__type': 'ProductSwap', 'data': input.toMap()};
    }
    if (input is AdditiveListArgs) {
      return {'__type': 'AdditiveListArgs', 'data': input.toMap()};
    }
    return input;
  }
}

class _RouteDecoder extends Converter<Object?, Object?> {
  const _RouteDecoder();

  @override
  Object? convert(Object? input) {
    if (input == null) return null;
    if (input is Map<String, dynamic>) {
      final type = input['__type'];
      final data = input['data'] as Map<String, dynamic>?;
      if (type == null || data == null) return input;

      switch (type) {
        case 'AIInsight':
          return AIInsight.fromMap(data);
        case 'BodyPattern':
          return BodyPattern.fromMap(data);
        case 'ScanResult':
          return ScanResult.fromMap(data);
        case 'ScanResultArgs':
          return ScanResultArgs.fromMap(data);
        case 'InsightSummary':
          return InsightSummary.fromMap(data);
        case 'SymptomLog':
          return SymptomLog.fromMap(data);
        case 'AdditiveConcern':
          return AdditiveConcern.fromMap(data);
        case 'ScanListDetailArgs':
          return ScanListDetailArgs.fromMap(data);
        case 'ProductSwap':
          return ProductSwap.fromMap(data);
        case 'AdditiveListArgs':
          return AdditiveListArgs.fromMap(data);
        default:
          return input;
      }
    }
    return input;
  }
}
