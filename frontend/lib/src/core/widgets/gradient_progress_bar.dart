import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientProgressBar extends StatelessWidget {
  final double value;
  final double? height;
  final Gradient? gradient;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barHeight = height ?? 8.0;
        final filledWidth = (value.clamp(0.0, 1.0) * constraints.maxWidth);

        return Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: AppColors.divider,
            borderRadius: BorderRadius.circular(barHeight / 2),
          ),
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: filledWidth,
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.progressGradient,
                  borderRadius: BorderRadius.circular(barHeight / 2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
