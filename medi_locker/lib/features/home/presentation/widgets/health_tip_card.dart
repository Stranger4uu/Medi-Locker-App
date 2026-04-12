import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class HealthTipCard extends StatelessWidget {
  const HealthTipCard({super.key});

  static const _tips = [
    'Drink at least 8 glasses of water daily to support kidney function and energy levels.',
    'Walk for 30 minutes a day — it reduces the risk of heart disease by up to 35%.',
    'Sleep 7–9 hours each night. Poor sleep weakens immunity and increases stress hormones.',
    'Eat a rainbow of vegetables daily to get a wide range of vitamins and antioxidants.',
    'Limit processed foods and added sugars to maintain healthy blood pressure and weight.',
    'Wash your hands regularly — it is the single most effective way to prevent infection.',
    'Take 5 deep breaths when stressed. It activates the parasympathetic nervous system.',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tip = _tips[DateTime.now().day % _tips.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lightbulb_outline,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warning),
                ),
                const SizedBox(height: 4),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
