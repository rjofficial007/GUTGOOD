part of 'smart_insight_detail_screen.dart';

/// Smart insight factor icon helper.

String _smartInsightFactorGlyph(String icon) => switch (icon.toLowerCase()) {
    'milk' => '🥛',
    'utensils' => '🍽',
    'leaf' => '🥬',
    'wheat' => '🌾',
    'droplet' => '💧',
    _ => '•',
  };

