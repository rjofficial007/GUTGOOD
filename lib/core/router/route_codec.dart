import 'dart:convert';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/route_arguments.dart';
import 'package:gutgood/core/models/scan_result.dart';

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
      return {'__type': 'AIInsight', 'data': input.toMap()};
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
        default:
          return input;
      }
    }
    return input;
  }
}
