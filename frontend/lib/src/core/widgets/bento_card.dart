import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.gradient,
    this.borderRadius,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null ? AppColors.white : null,
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: child,
    );
  }
}
