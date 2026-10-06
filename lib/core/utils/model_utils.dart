import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class ModelUtils {
  /// 🟢 NEW: Global safe JSON encoder that handles Firestore Timestamps and DateTimes.
  /// Use this instead of standard jsonEncode to prevent 'Converting object to an
  /// encodable object failed' crashes.
  static String safeJsonEncode(Object? object, {bool indent = false}) {
    try {
      if (indent) {
        return const JsonEncoder.withIndent('  ', toSafeEncodable).convert(object);
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
    if (nonEncodable is Timestamp) return nonEncodable.toDate().toUtc().toIso8601String();

    // 🚀 Robust Duck-Typing: handle objects from other libraries that might
    // contain Timestamp-like properties (seconds/nanoseconds) or toDate() methods.
    try {
      final dynamic obj = nonEncodable;
      // ignore: avoid_dynamic_calls
      if (obj.runtimeType.toString().contains('Timestamp')) {
        // ignore: avoid_dynamic_calls
        return obj.toDate().toUtc().toIso8601String();
      }
      // ignore: avoid_dynamic_calls
      if (obj.toMap != null) {
        // ignore: avoid_dynamic_calls
        return obj.toMap();
      }
      // ignore: avoid_dynamic_calls
      if (obj.toJson != null) {
        // ignore: avoid_dynamic_calls
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
    final n = (value is num) ? value : num.tryParse(value?.toString() ?? '');
    if (n == null || !n.isFinite) return fallback.clamp(min, max);
    return n.clamp(min, max).toInt();
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

  // Product scoring lives in `yuka_score.dart` (Yuka-style 60/30/10).

  static int computeMealScore({int? novaGroup, Map<String, dynamic>? balance, Map<String, dynamic>? nutrientLevels, String? impactType, bool? isOrganic}) {
    // Base score for a standard meal
    var score = 60;

    // Organic certification bonus
    if (isOrganic == true) {
      score += 10;
    }

    // Adjust based on NOVA group (processing)
    switch (novaGroup) {
      case 1:
        score += 20; // Unprocessed (Fruits, veg, meat)
      case 2:
        score += 10; // Culinary ingredients
      case 3:
        score += 0; // Processed (Bread, cheese, simple restaurant)
      case 4:
        score -= 20; // Ultra-processed (Fast food, heavy sauces)
    }

    // Adjust based on nutritional balance (from 'meal' block)
    if (balance != null) {
      final protein = balance['protein']?.toString().toLowerCase();
      final fiber = balance['fiber']?.toString().toLowerCase();

      if (protein == 'high' || protein == 'good') score += 5;
      if (protein == 'low' || protein == 'poor') score -= 5;

      if (fiber == 'high' || fiber == 'good') score += 10;
      if (fiber == 'moderate') score += 5;
      if (fiber == 'low' || fiber == 'poor') score -= 10;
    }

    // Adjust based on nutrient levels (from 'scan' block)
    if (nutrientLevels != null) {
      if (nutrientLevels['sugars']?.toString().toLowerCase() == 'high') score -= 15;
      if (nutrientLevels['salt']?.toString().toLowerCase() == 'high') score -= 10;
      if (nutrientLevels['fat']?.toString().toLowerCase() == 'high') score -= 5;
    }

    // Impact override
    if (impactType == 'positive' || impactType == 'healing') score += 10;
    if (impactType == 'negative' || impactType == 'trigger') score -= 20;

    return score.clamp(1, 100).toInt();
  }

  /// Friendly nutrient names for OFF's `en:nutriscore-missing-nutrition-data-*`
  /// tags, so we can say "missing sodium" rather than "missing-nutrition-data-sodium".
  static const Map<String, String> _nutrientLabels = {
    'sodium': 'sodium',
    'salt': 'salt',
    'sugars': 'sugar',
    'sugar': 'sugar',
    'saturated-fat': 'saturated fat',
    'saturated_fat': 'saturated fat',
    'fat': 'fat',
    'fiber': 'fibre',
    'fibre': 'fibre',
    'proteins': 'protein',
    'protein': 'protein',
    'energy': 'calories',
    'fruits-vegetables-nuts': 'fruit and veg content',
  };

  /// Explains, in plain English, why Open Food Facts could not compute a
  /// Nutri-Score — or `null` when the tags don't say.
  ///
  /// OFF publishes the reason in `misc_tags`:
  ///   en:nutriscore-missing-nutrition-data-sodium
  ///   en:nutriscore-missing-category
  ///   en:nutrition-not-enough-data-to-compute-nutrition-score
  ///
  /// Without this an unscorable product simply shows a neutral score and the
  /// user is left guessing whether the app is broken. Saying what is missing
  /// also invites them to contribute it back to OFF.
  static String? unscorableReason(List<String>? miscTags) {
    final tags = miscTags;
    if (tags == null || tags.isEmpty) return null;

    final relevant = tags.where((t) => t.startsWith('en:nutriscore') || t.startsWith('en:nutrition')).toSet();
    if (relevant.isEmpty) return null;

    // Most specific first: a named missing nutrient beats a generic
    // "not computed", which tells the user nothing.
    final missingNutrients = <String>[];
    for (final tag in relevant) {
      final m = RegExp(r'^en:nutriscore-missing-nutrition-data-(.+)$').firstMatch(tag);
      if (m != null) missingNutrients.add(m.group(1)!);
    }

    if (missingNutrients.isNotEmpty) {
      final names = missingNutrients.map((k) => _nutrientLabels[k] ?? k.replaceAll('_', ' ').replaceAll('-', ' ')).toSet().toList();
      final joined = names.length == 1 ? names.single : '${names.take(names.length - 1).join(', ')} and ${names.last}';
      return "Open Food Facts is missing $joined for this product, so we can't "
          'score it yet. You could add it and help everyone who scans this.';
    }

    if (relevant.contains('en:nutriscore-missing-category')) {
      return "Open Food Facts is missing this product's category, so a "
          "Nutri-Score can't be worked out yet.";
    }

    if (relevant.any((t) => t.contains('not-enough-data') || t == 'en:nutriscore-not-computed' || t == 'en:nutriscore-missing-nutrition-data')) {
      return "Open Food Facts doesn't have enough nutrition data for this "
          'product yet, so there is nothing to score.';
    }

    return null;
  }
}

/// One explainable input to the deterministic gut score.
class ScoreFactor extends Equatable {
  const ScoreFactor({required this.label, required this.delta, required this.phrase});

  /// Row display, e.g. 'Fiber 6g / 100g' or 'Higher-concern additives ×2'.
  final String label;

  /// Signed point contribution, e.g. +5 or -16.
  final int delta;

  /// Sentence fragment for the "here's why" summary, e.g. 'good fiber'.
  final String phrase;

  bool get isPositive => delta > 0;

  @override
  List<Object?> get props => [label, delta, phrase];
}
