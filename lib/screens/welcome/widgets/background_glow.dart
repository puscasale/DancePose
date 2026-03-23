import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class BackgroundGlow extends StatelessWidget {
  const BackgroundGlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _glowCircle(
            size: 220,
            color: AppColors.primary.withValues(alpha: 0.18),
          ),
        ),
        Positioned(
          top: 180,
          right: -50,
          child: _glowCircle(
            size: 180,
            color: AppColors.secondary.withValues(alpha: 0.14),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -40,
          child: _glowCircle(
            size: 170,
            color: AppColors.highlight.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }

  Widget _glowCircle({required double size, required Color color}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 80,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}