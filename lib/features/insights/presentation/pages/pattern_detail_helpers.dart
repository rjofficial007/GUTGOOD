part of 'pattern_detail_screen.dart';

/// Pattern detail factor icon helper.

String _patternFactorGlyph(String icon) => switch (icon.toLowerCase()) {
    'milk' => '🥛',
    'utensils' => '🍽',
    'leaf' => '🥬',
    'wheat' => '🌾',
    'droplet' => '💧',
    _ => '•',
  };

