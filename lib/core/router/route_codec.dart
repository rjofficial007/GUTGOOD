import 'dart:convert';

import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// go_router extra codec: extras are serialized as JSON
/// so every non-primitive type passed as state.extra in
/// app_router MUST be registered here or navigation throws.
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
    Object? encoded;
    if (input is AIInsight) {
      encoded = {'__type': 'AIInsight', 'data': input.toJsonMap()};
    } else if (input is BodyPattern) {
      encoded = {'__type': 'BodyPattern', 'data': input.toMap()};
    } else if (input is ScanResult) {
      encoded = {'__type': 'ScanResult', 'data': input.toMap()};
    } else if (input is ScanResultArgs) {
      encoded = {'__type': 'ScanResultArgs', 'data': input.toMap()};
    } else if (input is InsightSummary) {
      encoded = {'__type': 'InsightSummary', 'data': input.toMap()};
    } else if (input is SymptomLog) {
      encoded = {'__type': 'SymptomLog', 'data': input.toJsonMap()};
    } else if (input is MealLog) {
      encoded = {'__type': 'MealLog', 'data': input.toMap()};
    } else if (input is AdditiveConcern) {
      encoded = {'__type': 'AdditiveConcern', 'data': input.toMap()};
    } else if (input is ScanListDetailArgs) {
      encoded = {'__type': 'ScanListDetailArgs', 'data': input.toMap()};
    } else if (input is ProductSwap) {
      encoded = {'__type': 'ProductSwap', 'data': input.toMap()};
    } else if (input is AdditiveListArgs) {
      encoded = {'__type': 'AdditiveListArgs', 'data': input.toMap()};
    } else if (input is HighlightDetailArgs) {
      encoded = {'__type': 'HighlightDetailArgs', 'data': input.toMap()};
    } else {
      encoded = input;
    }

    try {
      return jsonDecode(ModelUtils.safeJsonEncode(encoded));
    } catch (_) {
      return encoded;
    }
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
        case 'MealLog':
          return MealLog.fromMap(data);
        case 'AdditiveConcern':
          return AdditiveConcern.fromMap(data);
        case 'ScanListDetailArgs':
          return ScanListDetailArgs.fromMap(data);
        case 'ProductSwap':
          return ProductSwap.fromMap(data);
        case 'AdditiveListArgs':
          return AdditiveListArgs.fromMap(data);
        case 'HighlightDetailArgs':
          return HighlightDetailArgs.fromMap(data);
        default:
          return input;
      }
    }
    return input;
  }
}
