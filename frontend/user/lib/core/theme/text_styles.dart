import 'package:flutter/material.dart';
import 'colors.dart';

class AppTextStyles {
  static const double _height = 1.3;

  static TextTheme textTheme(AppPalette p) {
    final base = TextStyle(color: p.textPrimary, height: _height);

    return TextTheme(
      headlineLarge: base.copyWith(fontSize: 24, fontWeight: FontWeight.w700),
      headlineMedium: base.copyWith(fontSize: 20, fontWeight: FontWeight.w700),
      titleLarge: base.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyMedium: base.copyWith(fontSize: 14, fontWeight: FontWeight.w400),
      bodySmall: base.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: p.textSecondary,
      ),
    );
  }

  static TextStyle button(AppPalette p) => TextStyle(
    height: _height,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
    color: p.textPrimary,
  );

  static TextStyle inputHint(AppPalette p) =>
      TextStyle(height: _height, fontSize: 14, color: p.textSecondary);

  static TextStyle inputHelper(AppPalette p) =>
      TextStyle(height: _height, fontSize: 12, color: p.textSecondary);

  static TextStyle inputError() => const TextStyle(
    height: _height,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
  );
}
