import 'dart:convert';

class ModelUtils {
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

  /// Clamps a raw AI-provided numeric score into a safe UI range.
  ///
  /// 🟢 NEW: previously `ScanResult.fromMap` trusted the AI's `score` field
  /// verbatim and fed it straight into `value: score / 100` progress
  /// indicators. A single malformed response (e.g. score: 140, or a
  /// negative "penalty" score) would silently render a broken/overflowing
  /// gauge. This is the single place all score parsing should go through.
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

    return list.map((e) {
      if (e is Map) {
        return fromMap(Map<String, dynamic>.from(e));
      } else if (e != null) {
        // Fallback for when AI returns [ "item1", "item2" ] instead of maps.
        // We try to "map-ify" the string if possible, or use a dummy map.
        // Most models expect a 'name' or 'title'.
        return fromMap({'name': e.toString(), 'title': e.toString()});
      }
      return null;
    }).whereType<T>().toList();
  }

  /// Robustly extracts JSON from a string that might contain noise
  /// (Markdown fences, conversational preamble/postamble around a
  /// [SCAN]/[MEAL] block, etc.).
  ///
  /// 🟢 FIXED: the previous implementation used
  /// `raw.indexOf(startChar)` / `raw.lastIndexOf(endChar)`, which breaks
  /// as soon as the surrounding prose (e.g. an `"impact"` sentence, or a
  /// second unrelated JSON-looking fragment) contains its own `{`/`}` or
  /// `[`/`]` characters — a very common occurrence in these prompts since
  /// `impact`/`summary` text is free-form. This version does a proper
  /// balanced-bracket scan that ignores brackets inside string literals
  /// (including escaped quotes), so it finds the FIRST COMPLETE top-level
  /// JSON value rather than an arbitrary first-to-last span.
  static String? extractJson(String? raw, {bool isArray = false}) {
    if (raw == null || raw.isEmpty) return null;

    final startChar = isArray ? '[' : '{';
    final endChar = isArray ? ']' : '}';

    final startIndex = raw.indexOf(startChar);
    if (startIndex == -1) {
      return raw.replaceAll('```json', '').replaceAll('```', '').trim();
    }

    var depth = 0;
    var inString = false;
    var escapeNext = false;

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

      if (char == startChar) {
        depth++;
      } else if (char == endChar) {
        depth--;
        if (depth == 0) {
          final candidate = raw.substring(startIndex, i + 1);
          // Sanity check: must actually parse. If not, fall back to the
          // old permissive behavior rather than returning something we
          // know is broken.
          try {
            jsonDecode(candidate);
            return candidate;
          } catch (_) {
            break;
          }
        }
      }
    }

    // Fallback: balanced scan failed (e.g. truncated stream mid-object).
    // Try the last matching close bracket as a best-effort recovery,
    // same as the legacy behavior, so partial/streaming calls don't
    // regress to returning nothing.
    final endIndex = raw.lastIndexOf(endChar);
    if (endIndex > startIndex) {
      return raw.substring(startIndex, endIndex + 1);
    }

    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }
}
