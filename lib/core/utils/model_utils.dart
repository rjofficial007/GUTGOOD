import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';

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

  /// Deterministic calculation for the Gut Score based on factual product data.
  ///
  /// This formula is the "Ground Truth" engine that translates Nutri-Score,
  /// NOVA processing group, fiber/protein/sugar/salt levels, and additive
  /// concern levels into a 0-100 score.
  ///
  /// Design guarantees:
  /// - Additives are penalized by CONCERN (low/moderate/higher), never by count.
  /// - Calories are intentionally NOT an input: energy alone says nothing about
  ///   gut impact, and penalizing it would punish wholesome calorie-dense foods.
  /// - All nutrient inputs are per-100g concentrations, so the score is
  ///   inherently serving-size normalized.
  static int computeDeterministicScore({String? nutriscore, int? novaGroup, num? fiberG, num? proteinG, num? sugarG, num? saltG, num? saturatedFatG, List<AdditiveConcern>? additiveConcerns}) {
    final factors = explainDeterministicScore(
      nutriscore: nutriscore,
      novaGroup: novaGroup,
      fiberG: fiberG,
      proteinG: proteinG,
      sugarG: sugarG,
      saltG: saltG,
      saturatedFatG: saturatedFatG,
      additiveConcerns: additiveConcerns,
    );
    return (50 + factors.fold(0, (sum, f) => sum + f.delta)).clamp(0, 100).toInt();
  }

  /// Same formula as [computeDeterministicScore], but returns the individual
  /// factors so the UI can explain *why* a score is what it is.
  static List<ScoreFactor> explainDeterministicScore({
    String? nutriscore,
    int? novaGroup,
    num? fiberG,
    num? proteinG,
    num? sugarG,
    num? saltG,
    num? saturatedFatG,
    List<AdditiveConcern>? additiveConcerns,
  }) {
    final factors = <ScoreFactor>[];

    switch (nutriscore?.toUpperCase()) {
      case 'A':
        factors.add(const ScoreFactor(label: 'Nutri-Score A', delta: 25, phrase: 'an excellent Nutri-Score of A'));
      case 'B':
        factors.add(const ScoreFactor(label: 'Nutri-Score B', delta: 15, phrase: 'a good Nutri-Score of B'));
      case 'C':
        break;
      case 'D':
        factors.add(const ScoreFactor(label: 'Nutri-Score D', delta: -15, phrase: 'a poor Nutri-Score of D'));
      case 'E':
        factors.add(const ScoreFactor(label: 'Nutri-Score E', delta: -25, phrase: 'a very poor Nutri-Score of E'));
    }

    switch (novaGroup) {
      case 1:
        factors.add(const ScoreFactor(label: 'NOVA 1 · Unprocessed', delta: 10, phrase: 'minimal processing'));
      case 2:
        factors.add(const ScoreFactor(label: 'NOVA 2 · Lightly processed', delta: 5, phrase: 'light processing'));
      case 3:
        break;
      case 4:
        factors.add(const ScoreFactor(label: 'NOVA 4 · Ultra-processed', delta: -10, phrase: 'ultra-processing (NOVA 4)'));
    }

    // Conservative nudges from raw nutrient values (per 100g)
    if (fiberG != null && fiberG >= 5) factors.add(ScoreFactor(label: 'Fiber ${_fmtG(fiberG)} / 100g', delta: 5, phrase: 'good fiber'));
    if (proteinG != null && proteinG >= 10) factors.add(ScoreFactor(label: 'Protein ${_fmtG(proteinG)} / 100g', delta: 3, phrase: 'solid protein'));
    if (sugarG != null && sugarG >= 20) factors.add(ScoreFactor(label: 'Sugars ${_fmtG(sugarG)} / 100g', delta: -5, phrase: 'high sugar'));
    if (saltG != null && saltG >= 1.5) factors.add(ScoreFactor(label: 'Salt ${_fmtG(saltG)} / 100g', delta: -5, phrase: 'high sodium'));
    if (saturatedFatG != null && saturatedFatG >= 5) {
      factors.add(ScoreFactor(label: 'Saturated fat ${_fmtG(saturatedFatG)} / 100g', delta: -3, phrase: 'high saturated fat'));
    }

    // Concern-based additive penalties (never count-based), each band capped.
    if (additiveConcerns != null && additiveConcerns.isNotEmpty) {
      var low = 0, moderate = 0, higher = 0;
      for (final c in additiveConcerns) {
        switch (c.level) {
          case AdditiveConcernLevel.low:
          case AdditiveConcernLevel.unknown:
            low++;
          case AdditiveConcernLevel.moderate:
            moderate++;
          case AdditiveConcernLevel.higher:
            higher++;
        }
      }
      final lowPenalty = min(low, 3);
      if (lowPenalty > 0) {
        factors.add(ScoreFactor(label: 'Low-concern additives ×$low', delta: -lowPenalty, phrase: low == 1 ? 'a low-concern additive' : 'a few low-concern additives'));
      }
      final moderatePenalty = min(moderate * 3, 12);
      if (moderatePenalty > 0) {
        factors.add(
          ScoreFactor(label: 'Moderate-concern additives ×$moderate', delta: -moderatePenalty, phrase: moderate == 1 ? '1 moderate-concern additive' : '$moderate moderate-concern additives'),
        );
      }
      final higherPenalty = min(higher * 8, 24);
      if (higherPenalty > 0) {
        factors.add(ScoreFactor(label: 'Higher-concern additives ×$higher', delta: -higherPenalty, phrase: higher == 1 ? '1 higher-concern additive' : '$higher higher-concern additives'));
      }
    }

    return factors;
  }

  /// Builds the personalized "here's why" sentence from score [factors].
  ///
  /// Examples:
  /// - "Good fiber and a good Nutri-Score of B, but ultra-processing (NOVA 4)
  ///   and 2 higher-concern additives pull the score down."
  /// - "Minimal processing and solid protein lift this score."
  /// - "High sugar and high sodium pull this score down."
  static String scoreExplanationSentence(List<ScoreFactor> factors) {
    final positives = factors.where((f) => f.isPositive).toList()..sort((a, b) => b.delta.compareTo(a.delta));
    final negatives = factors.where((f) => !f.isPositive).toList()..sort((a, b) => a.delta.compareTo(b.delta));
    final posPhrases = positives.take(2).map((f) => f.phrase).toList();
    final negPhrases = negatives.take(2).map((f) => f.phrase).toList();

    String join(List<String> parts) => parts.length == 2 ? '${parts[0]} and ${parts[1]}' : parts.join(', ');
    String cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

    if (posPhrases.isNotEmpty && negPhrases.isNotEmpty) {
      return '${cap(join(posPhrases))}, but ${join(negPhrases)} pull the score down.';
    }
    if (posPhrases.isNotEmpty) return '${cap(join(posPhrases))} lift${posPhrases.length == 1 ? 's' : ''} this score.';
    if (negPhrases.isNotEmpty) return '${cap(join(negPhrases))} pull${negPhrases.length == 1 ? 's' : ''} this score down.';
    return 'An average mix with no standout strengths or concerns.';
  }

  static String _fmtG(num v) => v == v.toInt() ? '${v.toInt()}g' : '${v.toStringAsFixed(1)}g';

  /// 🟢 NEW: Heuristic calculation for Meal Scores based on AI balance and processing.
  /// Used as a fallback when AI returns 0 for a meal scan.
  static int computeMealScore({int? novaGroup, Map<String, dynamic>? balance, Map<String, dynamic>? nutrientLevels, String? impactType}) {
    // Base score for a standard meal
    var score = 60;

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
}

/// One explainable input to the deterministic gut score.
class ScoreFactor {
  const ScoreFactor({required this.label, required this.delta, required this.phrase});

  /// Row display, e.g. 'Fiber 6g / 100g' or 'Higher-concern additives ×2'.
  final String label;

  /// Signed point contribution, e.g. +5 or -16.
  final int delta;

  /// Sentence fragment for the "here's why" summary, e.g. 'good fiber'.
  final String phrase;

  bool get isPositive => delta > 0;
}
