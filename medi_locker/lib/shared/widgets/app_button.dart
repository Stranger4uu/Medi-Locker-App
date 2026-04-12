import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppButtonVariant { primary, outline, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final AppButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onTap,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.height = 52,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = isDark ? AppColors.primaryLight : AppColors.primary;
        fg = isDark ? AppColors.primaryDark : Colors.white;
        border = null;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.primaryLight : AppColors.primary;
        border = Border.all(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            width: 1.5);
        break;
      case AppButtonVariant.danger:
        bg = Colors.transparent;
        fg = AppColors.error;
        border = Border.all(color: AppColors.error, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        border = null;
        break;
    }

    return GestureDetector(
      onTap: (isLoading || onTap == null) ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          color: (isLoading || onTap == null)
              ? bg.withValues(alpha: 0.5)
              : bg,
          borderRadius: BorderRadius.circular(14),
          border: border,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: fg,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: fg, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: fg,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
