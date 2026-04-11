import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colors
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF66BB6A);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryContainer = Color(0xFFE8F5E9);

  // Accent
  static const Color accent = Color(0xFF00C853);

  // Backgrounds — light
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color cardLight = Color(0xFFFFFFFF);

  // Backgrounds — dark
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF252525);

  // Text — light
  static const Color textPrimaryLight = Color(0xFF1A1A1A);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textHintLight = Color(0xFFBDBDBD);

  // Text — dark
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color textHintDark = Color(0xFF616161);

  // Semantic
  static const Color error = Color(0xFFE53935);
  static const Color errorContainer = Color(0xFFFFEBEE);
  static const Color warning = Color(0xFFFB8C00);
  static const Color warningContainer = Color(0xFFFFF8E1);
  static const Color success = Color(0xFF43A047);
  static const Color successContainer = Color(0xFFE8F5E9);
  static const Color info = Color(0xFF1E88E5);
  static const Color infoContainer = Color(0xFFE3F2FD);

  // Escalation (Cura danger warning)
  static const Color escalation = Color(0xFFE53935);
  static const Color escalationContainer = Color(0xFFFFEBEE);

  // Border
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF333333);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  );

  static const LinearGradient splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
  );
}