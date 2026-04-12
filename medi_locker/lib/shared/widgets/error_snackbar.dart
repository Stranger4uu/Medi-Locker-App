import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Convenience helpers for showing themed SnackBars.
/// Use these instead of raw ScaffoldMessenger calls everywhere.
class AppSnackBar {
  AppSnackBar._();

  static void error(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _build(
        message: message,
        icon: Icons.error_outline,
        color: AppColors.error,
      ),
    );
  }

  static void success(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _build(
        message: message,
        icon: Icons.check_circle_outline,
        color: AppColors.success,
      ),
    );
  }

  static void info(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      _build(
        message: message,
        icon: Icons.info_outline,
        color: AppColors.info,
      ),
    );
  }

  static SnackBar _build({
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 13, color: Colors.white)),
          ),
        ],
      ),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 3),
    );
  }
}
