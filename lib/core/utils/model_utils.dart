import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class ModelUtils {
  /// 🟢 NEW: Global safe JSON encoder that handles Firestore Timestamps and DateTimes.
  /// Use this instead of standard jsonEncode to prevent 'Converting object to an
  /// encodable object failed' crashes.
  static String safeJsonEncode(Object? object, {bool indent = false}) {
    try {
      if (indent) {
        return JsonEncoder.withIndent('  ', toSafeEncodable).convert(object);
      }
      return jsonEncode(object, toEncodable: toSafeEncodable);
    } catch (e) {
      return object?.toString() ?? '{}';
    }
  }

  /// 🟢 NEW: Standard 'toEncodable' logic for all JSON serialization in the app.
  static Object? toSafeEncodable(Object? nonEncodable) {
    if (nonEncodable == null) return null;
    if (nonEncodable is DateTime) return nonEncodable.toIso8601String();
    if (nonEncodable is Timestamp) return nonEncodable.toDate().toIso8601String();

    // 🚀 Robust Duck-Typing: handle objects from other libraries that might
    // contain Timestamp-like properties (seconds/nanoseconds) or toDate() methods.
    try {
      final dynamic obj = nonEncodable;
      if (obj.runtimeType.toString().contains('Timestamp')) {
        return obj.toDate().toIso8601String();
      }
      if (obj.toMap != null) {
        return obj.toMap();
      }
      if (obj.toJson != null) {
        return obj.toJson();
      }
    } catch (_) {}

    return nonEncodable.toString();
  }

  /// Safely parses a value that could be a String, a List of Strings, or any object into a joined string.
  static String? parseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).join(', ');
    }
    return value.toString();
  }

  /// Safely parses a value that could be a JSON string, a List, or a single item.
  static List<T> parseList<T>(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.whereType<T>().toList();
        } else if (decoded is T) {
          return [decoded];
        }
      } catch (_) {
        if ('' is T) return [value as T];
        return [];
      }
    }
    if (value is List) {
      return value.whereType<T>().toList();
    }
    if (value is T) {
      return [value];
    }
    return [];
  }

  /// Safely parses a value that could be a JSON string or a Map.
  static Map<String, dynamic> parseMap(dynamic value) {
    if (value == null) return {};
    if (value is String) {
      if (value.isEmpty) return {};
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {};
      }
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return {};
  }

  /// Safely parses a nested model that could be a JSON string or a Map.
  static T? parseNestedModel<T>(dynamic value, T Function(Map<String, dynamic>) fromMap) {
    if (value == null) return null;
    final map = parseMap(value);
    if (map.isEmpty) return null;
    return fromMap(map);
  }

  /// Safely parses a value that could be an int (1/0), bool, or String.
  static bool parseBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    if (value is String) {
      final s = value.toLowerCase().trim();
      if (s == '1' || s == 'true') return true;
      if (s == '0' || s == 'false') return false;
    }
    return defaultValue;
  }

  /// Safely parses a value into a num, handling String inputs from AI/Firestore.
  static num? parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value);
    return null;
  }

  /// Clamps a raw AI-provided numeric score into a safe UI range.
  static int parseScore(dynamic value, {int fallback = 0, int min = 0, int max = 100}) {
    final n = (value is num) ? value.toInt() : int.tryParse(value?.toString() ?? '');
    if (n == null) return fallback;
    return n.clamp(min, max);
  }

  /// Safely parses a list of nested models.
  static List<T> parseModelList<T>(dynamic value, T Function(Map<String, dynamic>) fromMap) {
    if (value == null) return [];
    List list;
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          list = decoded;
        } else {
          return [];
        }
      } catch (_) {
        return [];
      }
    } else if (value is List) {
      list = value;
    } else {
      return [];
    }

    return list
        .map((e) {
          if (e is Map) {
            return fromMap(Map<String, dynamic>.from(e));
          } else if (e != null) {
            final s = e.toString();
            return fromMap({'name': s, 'title': s, 'food': s, 'text': s});
          }
          return null;
        })
        .whereType<T>()
        .toList();
  }

  /// Robustly extracts and optionally "fixes" truncated JSON from a string.
  ///
  /// LLMs occasionally truncate responses due to token limits. This method
  /// performs a balanced-bracket scan and, if the input appears truncated
  /// (unbalanced), it attempts to close open brackets/braces to produce a
  /// parseable fragment.
  static String? extractJson(String? raw, {bool isArray = false}) {
    if (raw == null || raw.isEmpty) return null;

    final startChar = isArray ? '[' : '{';

    final startIndex = raw.indexOf(startChar);
    if (startIndex == -1) {
      return raw.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    var depth = 0;
    var inString = false;
    var escapeNext = false;
    final stack = <String>[];

    for (var i = startIndex; i < raw.length; i++) {
      final char = raw[i];

      if (escapeNext) {
        escapeNext = false;
        continue;
      }

      if (char == r'\' && inString) {
        escapeNext = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (inString) continue;

      if (char == '{' || char == '[') {
        stack.add(char == '{' ? '}' : ']');
        depth++;
      } else if (char == '}' || char == ']') {
        if (stack.isNotEmpty && stack.last == char) {
          stack.removeLast();
          depth--;
          if (depth == 0) {
            final candidate = raw.substring(startIndex, i + 1);
            try {
              jsonDecode(candidate);
              return candidate;
            } catch (_) {
              // Not valid yet, keep going
            }
          }
        }
      }
    }

    // If we reach here, the JSON is unbalanced (likely truncated).
    var current = raw.substring(startIndex).trim();

    // 🟢 DATA INTEGRITY: If the JSON was truncated immediately after a comma,
    // remove the trailing comma before force-closing to ensure validity.
    if (current.endsWith(',')) {
      current = current.substring(0, current.length - 1).trim();
    }

    // 1. Try force-closing the stack
    if (stack.isNotEmpty) {
      final buffer = StringBuffer(current);
      if (inString) buffer.write('"');
      for (final closing in stack.reversed) {
        buffer.write(closing);
      }
      final fix = buffer.toString();
      try {
        jsonDecode(fix);
        return fix;
      } catch (_) {}
    }

    // 2. Fallback to last closing char
    final lastBrace = current.lastIndexOf('}');
    final lastBracket = current.lastIndexOf(']');
    final lastEnd = lastBrace > lastBracket ? lastBrace : lastBracket;

    if (lastEnd != -1) {
      final candidate = current.substring(0, lastEnd + 1);
      try {
        jsonDecode(candidate);
        return candidate;
      } catch (_) {}
    }

    // 🟢 PRODUCTION SAFETY: Never return raw partial text if it fails decoding.
    // Returning null allows the caller to gracefully ignore the turn.
    try {
      final fallback = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      jsonDecode(fallback);
      return fallback;
    } catch (_) {
      return null;
    }
  }

  /// Deterministic calculation for the Gut Score based on factual product data.
  ///
  /// This formula is the "Ground Truth" engine that translates Nutri-Score,
  /// NOVA processing group, and fiber/protein/sugar/salt levels into a 0-100 score.
  static int computeDeterministicScore({String? nutriscore, int? novaGroup, num? fiberG, num? proteinG, num? sugarG, num? saltG, num? saturatedFatG}) {
    var score = 50;

    switch (nutriscore?.toUpperCase()) {
      case 'A':
        score += 25;
      case 'B':
        score += 15;
      case 'C':
        break;
      case 'D':
        score -= 15;
      case 'E':
        score -= 25;
    }

    switch (novaGroup) {
      case 1:
        score += 10;
      case 2:
        score += 5;
      case 3:
        break;
      case 4:
        score -= 10;
    }

    // Conservative nudges from raw nutrient values (per 100g)
    if (fiberG != null && fiberG >= 5) score += 5;
    if (proteinG != null && proteinG >= 10) score += 3;
    if (sugarG != null && sugarG >= 20) score -= 5;
    if (saltG != null && saltG >= 1.5) score -= 5;
    if (saturatedFatG != null && saturatedFatG >= 5) score -= 3;

    return score.clamp(0, 100);
  }
}
