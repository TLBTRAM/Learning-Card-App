import 'package:flutter/material.dart';

abstract final class AppTextStyles {
  static const _fallbacks = <String>['Helvetica Neue', 'Roboto', 'sans-serif'];

  static TextStyle _style(
    double size,
    double height, {
    FontWeight weight = FontWeight.w400,
  }) {
    return TextStyle(
      fontFamily: 'Arial',
      fontFamilyFallback: _fallbacks,
      fontSize: size,
      height: height,
      fontWeight: weight,
      letterSpacing: 0,
    );
  }

  static TextTheme textTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: _style(46, 1.08, weight: FontWeight.w700),
      displayMedium: _style(38, 1.1, weight: FontWeight.w700),
      headlineLarge: _style(32, 1.15, weight: FontWeight.w700),
      headlineMedium: _style(27, 1.18, weight: FontWeight.w700),
      headlineSmall: _style(23, 1.22, weight: FontWeight.w700),
      titleLarge: _style(20, 1.3, weight: FontWeight.w700),
      titleMedium: _style(16, 1.35, weight: FontWeight.w700),
      titleSmall: _style(14, 1.35, weight: FontWeight.w700),
      bodyLarge: _style(16, 1.5),
      bodyMedium: _style(14, 1.48),
      bodySmall: _style(12, 1.42),
      labelLarge: _style(14, 1.2, weight: FontWeight.w700),
      labelMedium: _style(12, 1.2, weight: FontWeight.w700),
      labelSmall: _style(11, 1.2, weight: FontWeight.w700),
    );
  }
}
