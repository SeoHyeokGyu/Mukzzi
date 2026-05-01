import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CharacterState { normal, happy, hungry, starving, sleeping }

enum CharacterStage { baby, teen, adult }

extension CharacterLevelExtension on int {
  CharacterStage get stage {
    if (this <= 2) return CharacterStage.baby;
    if (this <= 6) return CharacterStage.teen;
    return CharacterStage.adult;
  }
}

extension CharacterStateLabel on CharacterState {
  String get label {
    switch (this) {
      case CharacterState.normal:   return '정상';
      case CharacterState.happy:    return '행복';
      case CharacterState.hungry:   return '배고픔';
      case CharacterState.starving: return '굶주림';
      case CharacterState.sleeping: return '수면';
    }
  }

  String get message {
    switch (this) {
      case CharacterState.normal:   return '식사를 기록하면 먹찌가 성장해요';
      case CharacterState.happy:    return '맛있는 거 먹어서 기분 좋아요!';
      case CharacterState.hungry:   return '배가 고파요! 뭔가 드세요';
      case CharacterState.starving: return '배고파요... 밥 주세요';
      case CharacterState.sleeping: return '먹찌는 꿈나라 여행 중...';
    }
  }
}

class MukzziCharacter extends StatefulWidget {
  final CharacterState state;
  final double size;
  final int level;

  const MukzziCharacter({
    super.key,
    this.state = CharacterState.normal,
    this.size = 120,
    this.level = 1,
  });

  @override
  State<MukzziCharacter> createState() => _MukzziCharacterState();
}

class _MukzziCharacterState extends State<MukzziCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _breatheController;
  late final AnimationController _tailController;
  late final Animation<double> _breathe;
  late final Animation<double> _tail;

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    
    _tailController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _breathe = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );

    _tail = Tween<double>(begin: -4.0 * math.pi / 180, end: 8.0 * math.pi / 180).animate(
      CurvedAnimation(parent: _tailController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breatheController.dispose();
    _tailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathe, _tail]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _MukzziPainter(
            state: widget.state,
            stage: widget.level.stage,
            breatheValue: _breathe.value,
            tailAngle: _tail.value,
          ),
        );
      },
    );
  }
}

class _MukzziPainter extends CustomPainter {
  final CharacterState state;
  final CharacterStage stage;
  final double breatheValue;
  final double tailAngle;

  static const Color ink = Color(0xFF111111);
  static const Color accent = Color(0xFF2D6BFF);
  static const double strokeWidth = 2.0;

  _MukzziPainter({
    required this.state,
    required this.stage,
    required this.breatheValue,
    required this.tailAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double baseSize;
    final Offset centerOffset;

    switch (stage) {
      case CharacterStage.baby:
        baseSize = 160.0;
        centerOffset = const Offset(80, 80);
      case CharacterStage.teen:
        baseSize = 180.0;
        centerOffset = const Offset(90, 90);
      case CharacterStage.adult:
        baseSize = 200.0;
        centerOffset = const Offset(100, 110);
    }

    final scale = size.width / baseSize;
    canvas.scale(scale, scale);

    // Adaptive stroke width based on design spec
    final double adaptiveStroke;
    if (size.width <= 48) {
      adaptiveStroke = 3.0 / scale;
    } else if (size.width <= 80) {
      adaptiveStroke = 2.4 / scale;
    } else if (size.width <= 120) {
      adaptiveStroke = 2.0 / scale;
    } else {
      adaptiveStroke = 1.8 / scale;
    }

    final mainPaint = Paint()
      ..color = ink
      ..strokeWidth = adaptiveStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.fill;

    final accentStroke = Paint()
      ..color = accent
      ..strokeWidth = adaptiveStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // 0. Draw Ground Line (Static)
    final groundY = (stage == CharacterStage.baby) ? 60.0 : 
                    (stage == CharacterStage.teen) ? 100.0 : 115.0;
    canvas.drawLine(
      Offset(centerOffset.dx - 60, centerOffset.dy + groundY), 
      Offset(centerOffset.dx + 60, centerOffset.dy + groundY), 
      mainPaint..color = ink.withValues(alpha: 0.2)
    );
    mainPaint.color = ink; // Restore

    canvas.translate(centerOffset.dx, centerOffset.dy);

    // 1. Breathe Transform Start (Includes Body and Tail)
    canvas.save();
    // Origin is at bottom for breathing (90% point)
    final double breatheOriginY = (stage == CharacterStage.baby) ? 44.0 : 
                                  (stage == CharacterStage.teen) ? 78.0 : 92.0;
    canvas.translate(0, breatheOriginY);
    canvas.scale(breatheValue, breatheValue);
    canvas.translate(0, -breatheOriginY);

    // 2. Draw Tail (Animated separately but within breathe transform)
    _drawTail(canvas, mainPaint);

    // 3. Draw Body (White fill will naturally cover the tail's start point)
    _drawBody(canvas, fillPaint, mainPaint, accentPaint, accentStroke);

    // 4. Draw Face
    _drawFace(canvas, mainPaint, accentPaint, accentStroke);

    // 5. Breathe Transform End
    canvas.restore();
    
    // 6. Status Badges (Overlay - no breathing)
    _drawStatusBadge(canvas, accentPaint, accentStroke);
  }

  void _drawBody(Canvas canvas, Paint fill, Paint stroke, Paint accentFill, Paint accentStroke) {
    switch (stage) {
      case CharacterStage.baby:
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 100, height: 88), fill);
        canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 100, height: 88), stroke);
        
        // Ears
        final leftEar = Path()..moveTo(-34, -38)..lineTo(-28, -60)..lineTo(-12, -34)..close();
        final rightEar = Path()..moveTo(34, -38)..lineTo(28, -60)..lineTo(12, -34)..close();
        canvas.drawPath(leftEar, fill);
        canvas.drawPath(leftEar, stroke);
        canvas.drawPath(rightEar, fill);
        canvas.drawPath(rightEar, stroke);
        
        // Inner Ears
        final leftInner = Path()..moveTo(-30, -42)..lineTo(-28, -54)..lineTo(-18, -38)..close();
        final rightInner = Path()..moveTo(30, -42)..lineTo(28, -54)..lineTo(18, -38)..close();
        canvas.drawPath(leftInner, accentFill);
        canvas.drawPath(leftInner, accentStroke);
        canvas.drawPath(rightInner, accentFill);
        canvas.drawPath(rightInner, accentStroke);

        // Feet
        canvas.drawOval(Rect.fromCenter(center: const Offset(-18, 46), width: 22, height: 10), stroke);
        canvas.drawOval(Rect.fromCenter(center: const Offset(18, 46), width: 22, height: 10), stroke);

      case CharacterStage.teen:
        // Body (lower)
        final bodyPath = Path()
          ..moveTo(-56, 78)
          ..cubicTo(-56, 30, -40, 8, 0, 8)
          ..cubicTo(40, 8, 56, 30, 56, 78)
          ..close();
        canvas.drawPath(bodyPath, fill);
        canvas.drawPath(bodyPath, stroke);
        
        // Head
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, -12), width: 100, height: 92), fill);
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, -12), width: 100, height: 92), stroke);

        // Ears
        final leftEar = Path()..moveTo(-36, -42)..lineTo(-28, -68)..lineTo(-12, -38)..close();
        final rightEar = Path()..moveTo(36, -42)..lineTo(28, -68)..lineTo(12, -38)..close();
        canvas.drawPath(leftEar, fill);
        canvas.drawPath(leftEar, stroke);
        canvas.drawPath(rightEar, fill);
        canvas.drawPath(rightEar, stroke);

        // Inner Ears
        final leftInner = Path()..moveTo(-32, -46)..lineTo(-28, -60)..lineTo(-18, -42)..close();
        final rightInner = Path()..moveTo(32, -46)..lineTo(28, -60)..lineTo(18, -42)..close();
        canvas.drawPath(leftInner, accentFill);
        canvas.drawPath(leftInner, accentStroke);
        canvas.drawPath(rightInner, accentFill);
        canvas.drawPath(rightInner, accentStroke);

        // Feet
        canvas.drawOval(Rect.fromCenter(center: const Offset(-22, 78), width: 28, height: 12), Paint()..color = ink);
        canvas.drawOval(Rect.fromCenter(center: const Offset(22, 78), width: 28, height: 12), Paint()..color = ink);

        // Collar
        final collar = Path()..moveTo(-34, 36)..quadraticBezierTo(0, 50, 34, 36);
        canvas.drawPath(collar, Paint()..color = accent..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round);
        canvas.drawCircle(const Offset(0, 46), 4, accentFill);

      case CharacterStage.adult:
        // Body
        final bodyPath = Path()
          ..moveTo(-64, 90)
          ..cubicTo(-64, 36, -46, 10, 0, 10)
          ..cubicTo(46, 10, 64, 36, 64, 90)
          ..close();
        canvas.drawPath(bodyPath, fill);
        canvas.drawPath(bodyPath, stroke);
        
        // Head
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, -18), width: 116, height: 108), fill);
        canvas.drawOval(Rect.fromCenter(center: const Offset(0, -18), width: 116, height: 108), stroke);

        // Ears
        final leftEar = Path()..moveTo(-42, -54)..lineTo(-32, -84)..lineTo(-14, -48)..close();
        final rightEar = Path()..moveTo(42, -54)..lineTo(32, -84)..lineTo(14, -48)..close();
        canvas.drawPath(leftEar, fill);
        canvas.drawPath(leftEar, stroke);
        canvas.drawPath(rightEar, fill);
        canvas.drawPath(rightEar, stroke);

        // Inner Ears
        final leftInner = Path()..moveTo(-38, -56)..lineTo(-32, -76)..lineTo(-22, -52)..close();
        final rightInner = Path()..moveTo(38, -56)..lineTo(32, -76)..lineTo(22, -52)..close();
        canvas.drawPath(leftInner, accentFill);
        canvas.drawPath(leftInner, accentStroke);
        canvas.drawPath(rightInner, accentFill);
        canvas.drawPath(rightInner, accentStroke);

        // Feet
        canvas.drawOval(Rect.fromCenter(center: const Offset(-26, 92), width: 32, height: 14), Paint()..color = ink);
        canvas.drawOval(Rect.fromCenter(center: const Offset(26, 92), width: 32, height: 14), Paint()..color = ink);

        // Bowtie
        final leftBow = Path()..moveTo(-18, 40)..lineTo(-8, 32)..lineTo(-8, 50)..close();
        final rightBow = Path()..moveTo(18, 40)..lineTo(8, 32)..lineTo(8, 50)..close();
        canvas.drawPath(leftBow, accentFill);
        canvas.drawPath(leftBow, accentStroke);
        canvas.drawPath(rightBow, accentFill);
        canvas.drawPath(rightBow, accentStroke);
        canvas.drawRect(Rect.fromCenter(center: const Offset(0, 41), width: 12, height: 10), accentFill);
        canvas.drawRect(Rect.fromCenter(center: const Offset(0, 41), width: 12, height: 10), accentStroke);

        // Crown
        final crown = Path()
          ..moveTo(-22, -84)..lineTo(-16, -72)..lineTo(-8, -88)..lineTo(0, -72)
          ..lineTo(8, -88)..lineTo(16, -72)..lineTo(22, -84)..lineTo(22, -68)..lineTo(-22, -68)..close();
        canvas.drawPath(crown, accentFill);
        canvas.drawPath(crown, accentStroke);
    }
  }

  void _drawFace(Canvas canvas, Paint stroke, Paint accentFill, Paint accentStroke) {
    final offset = (stage == CharacterStage.baby) ? const Offset(0, 0) : 
                   (stage == CharacterStage.teen) ? const Offset(0, -12) : const Offset(0, -18);
    
    const eyeY = -4.0;
    final eyeX = (stage == CharacterStage.baby) ? 15.0 : 
                 (stage == CharacterStage.teen) ? 18.0 : 22.0;
    
    final pupilPaint = Paint()..color = ink..style = PaintingStyle.fill;

    switch (state) {
      case CharacterState.normal:
        canvas.drawCircle(Offset(-eyeX, offset.dy + eyeY), 2.5, pupilPaint);
        canvas.drawCircle(Offset(eyeX, offset.dy + eyeY), 2.5, pupilPaint);
      case CharacterState.happy:
        final leftHappy = Path()..moveTo(-eyeX - 4, offset.dy + eyeY)..quadraticBezierTo(-eyeX, offset.dy + eyeY - 6, -eyeX + 4, offset.dy + eyeY);
        final rightHappy = Path()..moveTo(eyeX - 4, offset.dy + eyeY)..quadraticBezierTo(eyeX, offset.dy + eyeY - 6, eyeX + 4, offset.dy + eyeY);
        canvas.drawPath(leftHappy, stroke);
        canvas.drawPath(rightHappy, stroke);
      case CharacterState.hungry:
        canvas.drawCircle(Offset(-eyeX, offset.dy + eyeY + 4), 2.2, pupilPaint);
        canvas.drawCircle(Offset(eyeX, offset.dy + eyeY + 4), 2.2, pupilPaint);
      case CharacterState.starving:
        canvas.drawLine(Offset(-eyeX - 5, offset.dy + eyeY - 2), Offset(-eyeX + 5, offset.dy + eyeY + 6), stroke);
        canvas.drawLine(Offset(-eyeX - 5, offset.dy + eyeY + 6), Offset(-eyeX + 5, offset.dy + eyeY - 2), stroke);
        canvas.drawLine(Offset(eyeX - 5, offset.dy + eyeY - 2), Offset(eyeX + 5, offset.dy + eyeY + 6), stroke);
        canvas.drawLine(Offset(eyeX - 5, offset.dy + eyeY + 6), Offset(eyeX + 5, offset.dy + eyeY - 2), stroke);
      case CharacterState.sleeping:
        final leftSleep = Path()..moveTo(-eyeX - 4, offset.dy + eyeY)..quadraticBezierTo(-eyeX, offset.dy + eyeY + 4, -eyeX + 4, offset.dy + eyeY);
        final rightSleep = Path()..moveTo(eyeX - 4, offset.dy + eyeY)..quadraticBezierTo(eyeX, offset.dy + eyeY + 4, eyeX + 4, offset.dy + eyeY);
        canvas.drawPath(leftSleep, stroke);
        canvas.drawPath(rightSleep, stroke);
    }

    final noseY = (stage == CharacterStage.baby) ? 8.0 : 
                  (stage == CharacterStage.teen) ? 0.0 : -4.0;
    final nosePath = Path()..moveTo(-3, offset.dy + noseY)..lineTo(3, offset.dy + noseY)..lineTo(0, offset.dy + noseY + 6)..close();
    canvas.drawPath(nosePath, accentFill);
    canvas.drawPath(nosePath, accentStroke);

    final mouthY = (stage == CharacterStage.baby) ? noseY + 6 : 
                   (stage == CharacterStage.teen) ? noseY + 6 : noseY + 8;
    
    switch (state) {
      case CharacterState.normal:
        canvas.drawPath(Path()..moveTo(0, offset.dy + mouthY)..quadraticBezierTo(-5, offset.dy + mouthY + 6, -10, offset.dy + mouthY + 2), stroke);
        canvas.drawPath(Path()..moveTo(0, offset.dy + mouthY)..quadraticBezierTo(5, offset.dy + mouthY + 6, 10, offset.dy + mouthY + 2), stroke);
      case CharacterState.happy:
        canvas.drawPath(Path()..moveTo(-10, offset.dy + mouthY + 2)..quadraticBezierTo(0, offset.dy + mouthY + 12, 10, offset.dy + mouthY + 2), stroke);
      case CharacterState.hungry:
        canvas.drawOval(Rect.fromCenter(center: Offset(0, offset.dy + mouthY + 8), width: 12, height: 8), Paint()..color = Colors.white..style = PaintingStyle.fill);
        canvas.drawOval(Rect.fromCenter(center: Offset(0, offset.dy + mouthY + 8), width: 12, height: 8), stroke);
        canvas.drawPath(Path()..moveTo(4, offset.dy + mouthY + 12)..quadraticBezierTo(6, offset.dy + mouthY + 20, 4, offset.dy + mouthY + 26), stroke); // Drool
      case CharacterState.starving:
        canvas.drawPath(Path()..moveTo(-8, offset.dy + mouthY + 8)..quadraticBezierTo(0, offset.dy + mouthY + 2, 8, offset.dy + mouthY + 8), stroke);
      case CharacterState.sleeping:
        canvas.drawPath(Path()..moveTo(-6, offset.dy + mouthY + 6)..quadraticBezierTo(0, offset.dy + mouthY + 10, 6, offset.dy + mouthY + 6), stroke);
    }

    if (stage != CharacterStage.baby) {
      final whiskerX = (stage == CharacterStage.teen) ? 50.0 : 58.0;
      final whiskerY = (stage == CharacterStage.teen) ? 12.0 : 6.0; // Lowered to cheek area
      const whiskerLen = 18.0;
      final whiskerPaint = Paint()..color = ink.withValues(alpha: 0.7)..strokeWidth = 1.5;
      
      canvas.drawLine(Offset(-whiskerX, offset.dy + whiskerY), Offset(-whiskerX + whiskerLen, offset.dy + whiskerY + 2), whiskerPaint);
      canvas.drawLine(Offset(-whiskerX, offset.dy + whiskerY + 6), Offset(-whiskerX + whiskerLen, offset.dy + whiskerY + 8), whiskerPaint);
      canvas.drawLine(Offset(whiskerX, offset.dy + whiskerY), Offset(whiskerX - whiskerLen, offset.dy + whiskerY + 2), whiskerPaint);
      canvas.drawLine(Offset(whiskerX, offset.dy + whiskerY + 6), Offset(whiskerX - whiskerLen, offset.dy + whiskerY + 8), whiskerPaint);
      
      if (stage == CharacterStage.adult) {
        canvas.drawLine(Offset(-whiskerX, offset.dy + whiskerY - 6), Offset(-whiskerX + whiskerLen, offset.dy + whiskerY - 4), whiskerPaint);
        canvas.drawLine(Offset(whiskerX, offset.dy + whiskerY - 6), Offset(whiskerX - whiskerLen, offset.dy + whiskerY - 4), whiskerPaint);
      }
    }
  }

  void _drawTail(Canvas canvas, Paint stroke) {
    canvas.save();
    
    final Offset tailOrigin;
    final Path tailPath = Path();

    switch (stage) {
      case CharacterStage.baby:
        tailOrigin = const Offset(30, 8);
        canvas.translate(tailOrigin.dx, tailOrigin.dy);
        canvas.rotate(tailAngle);
        tailPath..moveTo(0, 0)..quadraticBezierTo(20, -10, 14, -30);
      case CharacterStage.teen:
        tailOrigin = const Offset(50, 60);
        canvas.translate(tailOrigin.dx, tailOrigin.dy);
        canvas.rotate(tailAngle);
        tailPath..moveTo(0, 0)..quadraticBezierTo(36, -24, 26, -68);
      case CharacterStage.adult:
        tailOrigin = const Offset(58, 70);
        canvas.translate(tailOrigin.dx, tailOrigin.dy);
        canvas.rotate(tailAngle);
        tailPath..moveTo(0, 0)..quadraticBezierTo(42, -30, 30, -86);
    }
    
    canvas.drawPath(tailPath, stroke);
    canvas.restore();
  }

  void _drawStatusBadge(Canvas canvas, Paint accentFill, Paint accentStroke) {
    final Offset badgePos = (stage == CharacterStage.baby) ? const Offset(50, -50) : 
                             (stage == CharacterStage.teen) ? const Offset(60, -60) : const Offset(60, -90); // Raised for Adult crown

    switch (state) {
      case CharacterState.happy:
        final sparkle = Path()
          ..moveTo(badgePos.dx, badgePos.dy)..lineTo(badgePos.dx + 4, badgePos.dy + 8)
          ..lineTo(badgePos.dx + 12, badgePos.dy + 12)..lineTo(badgePos.dx + 4, badgePos.dy + 16)
          ..lineTo(badgePos.dx, badgePos.dy + 24)..lineTo(badgePos.dx - 4, badgePos.dy + 16)
          ..lineTo(badgePos.dx - 12, badgePos.dy + 12)..lineTo(badgePos.dx - 4, badgePos.dy + 8)..close();
        canvas.drawPath(sparkle, accentFill);
        canvas.drawPath(sparkle, accentStroke);
      case CharacterState.starving:
        canvas.drawCircle(badgePos, 11, accentFill);
        canvas.drawCircle(badgePos, 11, accentStroke);
        final tp = TextPainter(
          text: const TextSpan(text: '!', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, badgePos - Offset(tp.width / 2, tp.height / 2));
      case CharacterState.sleeping:
        final tp1 = TextPainter(
          text: const TextSpan(text: 'z', style: TextStyle(color: accent, fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          textDirection: TextDirection.ltr,
        );
        tp1.layout();
        tp1.paint(canvas, badgePos - const Offset(10, 0));
        final tp2 = TextPainter(
          text: const TextSpan(text: 'Z', style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'Poppins')),
          textDirection: TextDirection.ltr,
        );
        tp2.layout();
        tp2.paint(canvas, badgePos + const Offset(2, -14));
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(_MukzziPainter old) =>
      old.state != state || old.stage != stage || old.breatheValue != breatheValue || old.tailAngle != tailAngle;
}
