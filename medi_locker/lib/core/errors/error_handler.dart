import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_error.dart';

/// Global error handler utility.
/// Call `ErrorHandler.show(context, e)` from any catch block.
class ErrorHandler {
  ErrorHandler._();

  /// Convert any exception to AppError and show a SnackBar.
  static void show(BuildContext context, Object e) {
    final error = e is AppError ? e : AppError.fromException(e);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(error.message,
                style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show a success SnackBar.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message,
                style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Wrap async operations — returns null on error and shows SnackBar.
  static Future<T?> guard<T>(
    BuildContext context,
    Future<T> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (e) {
      show(context, e);
      return null;
    }
  }
}
