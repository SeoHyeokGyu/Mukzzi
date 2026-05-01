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
  final bool showPaperTexture;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.height,
    this.gradient,
    this.borderRadius,
    this.shadows,
    this.onTap,
    this.showPaperTexture = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final radius = borderRadius ?? BorderRadius.circular(tokens?.rCard ?? 20);
    
    Widget content = Container(
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: showPaperTexture 
            ? (tokens?.paper ?? const Color(0xFFFAFAFA))
            : (gradient == null ? (Theme.of(context).cardTheme.color ?? AppColors.surface) : null),
        gradient: showPaperTexture ? null : gradient,
        borderRadius: radius,
        boxShadow: shadows ?? AppColors.cardShadow,
      ),
      child: showPaperTexture 
          ? CustomPaint(
              painter: _GridPainter(tokens?.paperLine ?? const Color(0x14000000)),
              child: child,
            )
          : child,
    );

    if (onTap == null) return content;

    return ClipRRect(
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color lineColor;

  _GridPainter(this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;

    const double spacing = 16.0;

    // Draw dot grid
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.8, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
