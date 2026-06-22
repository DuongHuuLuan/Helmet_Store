import 'package:flutter/material.dart';

class AppPalette {
  final Color background;
  final Color surface;
  final Color surface2;

  final Color textPrimary;
  final Color textSecondary;

  final Color border;
  final Color divider;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surface2,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.divider,
  });
}

class AppColors {
  static const primary = Color(0xFF0F1E31); // navy
  static const secondary = Color(0xFFD6AA69); // gold

  // Status
  static const error = Color(0xFFFF4D4D);
  static const success = Color(0xFF3DDC84);

  // On colors
  static const onPrimary = Colors.white;
  static const onSecondary = Color(0xFF121218);
  static const textSecondary = Color.fromARGB(255, 29, 29, 39);

  static const dark = AppPalette(
    background: Color(0xFF0A1524),
    surface: Color(0xFF121F33),
    surface2: Color(0xFF162840),
    textPrimary: Color(0xFFF2F6FF),
    textSecondary: Color(0xFFB7C1D1),
    border: Color(0xFF223B5C),
    divider: Color(0xFF1B2E49),
  );

  static const light = AppPalette(
    background: Color(0xFFF7F4F1),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFF0F4FA),
    textPrimary: Color(0xFF0A1524),
    textSecondary: Color(0xFF4C5A70),
    border: Color(0xFFD7E0EC),
    divider: Color(0xFFE6ECF4),
  );
}
