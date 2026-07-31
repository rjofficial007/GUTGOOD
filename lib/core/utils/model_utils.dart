import 'dart:convert';

class ModelUtils {
  /// Safely parses a value that could be a JSON string or a List.
  static List<T> parseList<T>(dynamic value) {
    if (value == null) return [];
    if (value is String) {
      if (value.isEmpty) return [];
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          return decoded.cast<T>();
        }
      } catch (_) {
        return [];
      }
    }
    if (value is List) {
      return value.cast<T>();
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

    return list.map((e) => fromMap(Map<String, dynamic>.from(e))).toList();
  }
}
