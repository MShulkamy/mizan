import 'package:flutter/material.dart';

/// Central colour system for Mizan.
///
/// The palette is intentionally hand-tuned (deep teal + warm amber on a
/// neutral graphite base) rather than generated from a single seed, so the
/// app keeps a consistent identity across light and dark surfaces.
class AppColors {
  AppColors._();

  // Brand
  static const Color brand = Color(0xFF0E7C66);
  static const Color brandDark = Color(0xFF34D3AE);
  static const Color accent = Color(0xFFE8A33D);
  static const Color accentDark = Color(0xFFF0B45A);

  // Semantic
  static const Color income = Color(0xFF1E9E6A);
  static const Color incomeDark = Color(0xFF3DDC97);
  static const Color expense = Color(0xFFE4572E);
  static const Color expenseDark = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFD98324);

  // Light surfaces
  static const Color lightBg = Color(0xFFF4F7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEAF0F1);
  static const Color lightOutline = Color(0xFFDCE4E6);
  static const Color lightText = Color(0xFF0E1A1F);
  static const Color lightTextMuted = Color(0xFF5B6B72);

  // Dark surfaces
  static const Color darkBg = Color(0xFF080D11);
  static const Color darkSurface = Color(0xFF111A20);
  static const Color darkSurfaceAlt = Color(0xFF18242C);
  static const Color darkOutline = Color(0xFF25333C);
  static const Color darkText = Color(0xFFECF2F3);
  static const Color darkTextMuted = Color(0xFF8EA0A8);

  /// Colours assigned to spending categories. Kept distinct in both themes.
  static const List<Color> categoryPalette = <Color>[
    Color(0xFF0E7C66), // teal
    Color(0xFFE8A33D), // amber
    Color(0xFF4C6FFF), // indigo
    Color(0xFFE4572E), // coral
    Color(0xFF8E5BD9), // violet
    Color(0xFF1E9E6A), // green
    Color(0xFFD64550), // red
    Color(0xFF2AA7C4), // cyan
    Color(0xFFB4872E), // bronze
    Color(0xFF6B7A8F), // slate
  ];

  static Color categoryColor(int index) =>
      categoryPalette[index % categoryPalette.length];

  static Color byName(String name) {
    var hash = 0;
    for (final unit in name.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return categoryPalette[hash % categoryPalette.length];
  }
}
