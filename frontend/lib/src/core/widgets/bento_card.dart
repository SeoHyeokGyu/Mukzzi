import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? height;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.gradient,
    this.borderRadius,
    this.shadows,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(20);
    final container = Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradient == null
          ? (Theme.of(context).cardTheme.color ?? AppColors.surface)
          : null,
        gradient: gradient,
        borderRadius: radius,
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: child,
    );

    if (onTap == null) return container;

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: container,
        ),
      ),
    );
  }
}
