import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'cura_avatar.dart';

class CuraTypingIndicator extends StatefulWidget {
  const CuraTypingIndicator({super.key});

  @override
  State<CuraTypingIndicator> createState() => _CuraTypingIndicatorState();
}

class _CuraTypingIndicatorState extends State<CuraTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late List<Animation<double>> _dotAnims;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();

    _dotAnims = List.generate(3, (i) {
      final start = i * 0.2;
      final end = start + 0.4;
      return Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeInOut),
        ),
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const CuraAvatar(size: 28, radius: 8),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return AnimatedBuilder(
                  animation: _dotAnims[i],
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, _dotAnims[i].value),
                    child: Container(
                      width: 7, height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
