import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class CuraAvatar extends StatelessWidget {
  final double size;
  final double radius;

  const CuraAvatar({
    super.key,
    this.size = 32,
    this.radius = 10,
  });

  static const _assetPath = 'assets/images/cura_logo.jpg';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        _assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.smart_toy,
          color: AppColors.primary,
          size: size * 0.58,
        ),
      ),
    );
  }
}
