import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography for Mizan, built on the bundled Plus Jakarta Sans family.
class AppTypography {
  AppTypography._();

  static const String family = 'PlusJakartaSans';

  static TextTheme textTheme(Color primary, Color muted) {
    return TextTheme(
      displaySmall: TextStyle(
        fontFamily: family,
        fontSize: 32,
        height: 1.15,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: family,
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: family,
        fontSize: 20,
        height: 1.25,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: family,
        fontSize: 17,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: family,
        fontSize: 15,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: family,
        fontSize: 15,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: family,
        fontSize: 13.5,
        height: 1.4,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: family,
        fontSize: 12,
        height: 1.35,
        fontWeight: FontWeight.w500,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: family,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      labelSmall: TextStyle(
        fontFamily: family,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: muted,
      ),
    );
  }

  static TextTheme get light =>
      textTheme(AppColors.lightText, AppColors.lightTextMuted);

  static TextTheme get dark =>
      textTheme(AppColors.darkText, AppColors.darkTextMuted);
}
