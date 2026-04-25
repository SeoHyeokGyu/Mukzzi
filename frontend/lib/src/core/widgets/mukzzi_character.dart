import 'dart:math' as math;
import 'package:flutter/material.dart';

enum CharacterState { normal, hungry, starving, weak, happy }

extension CharacterStateLabel on CharacterState {
  String get label {
    switch (this) {
      case CharacterState.normal:   return '정상';
      case CharacterState.hungry:   return '배고픔';
      case CharacterState.starving: return '굶주림';
      case CharacterState.weak:     return '기력없음';
      case CharacterState.happy:    return '행복';
    }
  }

  String get message {
    switch (this) {
      case CharacterState.normal:   return '식사를 기록하면 먹찌가 성장해요';
      case CharacterState.hungry:   return '배가 고파요! 뭔가 드세요';
      case CharacterState.starving: return '배고파요... 밥 주세요';
      case CharacterState.weak:     return '기력이 없어요... 빨리 먹어요';
      case CharacterState.happy:    return '맛있는 거 먹어서 기분 좋아요!';
    }
  }
}

class _CharPalette {
  final Color body;
  final Color shade;
  final Color belly;
  final Color cheek;
  final Color pupil;

  const _CharPalette({
    required this.body,
    required this.shade,
    required this.belly,
    required this.cheek,
    required this.pupil,
  });
}

const _palettes = {
  CharacterState.normal: _CharPalette(
    body:  Color(0xFFFFE0A0),
    shade: Color(0xFFE8C070),
    belly: Color(0xFFFFF5D9),
    cheek: Color(0xFFFFB6C1),
    pupil: Color(0xFF3A2010),
  ),
  CharacterState.hungry: _CharPalette(
    body:  Color(0xFFFFD070),
    shade: Color(0xFFD9A840),
    belly: Color(0xFFFFECA0),
    cheek: Color(0xFFFFB6C1),
    pupil: Color(0xFF3A2010),
  ),
  CharacterState.starving: _CharPalette(
    body:  Color(0xFFF0907A),
    shade: Color(0xFFCC6855),
    belly: Color(0xFFF5C0A8),
    cheek: Color(0xFFFFAA99),
    pupil: Color(0xFF3A2010),
  ),
  CharacterState.weak: _CharPalette(
    body:  Color(0xFFC5C8D8),
    shade: Color(0xFFA0A5BB),
    belly: Color(0xFFE0E2EC),
    cheek: Color(0xFFC0B4C0),
    pupil: Color(0xFF585878),
  ),
  CharacterState.happy: _CharPalette(
    body:  Color(0xFFFFD166),
    shade: Color(0xFFE8AA30),
    belly: Color(0xFFFFECB0),
    cheek: Color(0xFFFF85A1),
    pupil: Color(0xFF3A2010),
  ),
};

class MukzziCharacter extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _MukzziPainter(state: state, level: level),
    );
  }
}

class _MukzziPainter extends CustomPainter {
  final CharacterState state;
  final int level;

  const _MukzziPainter({required this.state, required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.scale(scale, scale);

    final palette = _palettes[state]!;
    _drawBody(canvas, palette);
    _drawBelly(canvas, palette);
    _drawCheeks(canvas, palette);
    _drawEyes(canvas, palette);
    _drawMouth(canvas, palette);
    if (level >= 10) {
      _drawHat(canvas);
    } else if (level >= 5) {
      _drawLeaf(canvas);
    }
    _drawBadge(canvas);
  }

  void _drawBody(Canvas canvas, _CharPalette palette) {
    const bodyRect = Rect.fromLTWH(46, 26, 108, 148);

    canvas.drawOval(bodyRect, Paint()..color = palette.body);

    // Shade as radial gradient overlay
    canvas.save();
    canvas.clipPath(Path()..addOval(bodyRect));
    canvas.drawOval(
      bodyRect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.45, 0.25),
          radius: 0.75,
          colors: [Colors.transparent, palette.shade.withValues(alpha: 0.38)],
        ).createShader(bodyRect),
    );
    canvas.restore();
  }

  void _drawBelly(Canvas canvas, _CharPalette palette) {
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 128), width: 54, height: 42),
      Paint()..color = palette.belly.withValues(alpha: 0.7),
    );
  }

  void _drawCheeks(Canvas canvas, _CharPalette palette) {
    if (state == CharacterState.weak) return;
    final paint = Paint()..color = palette.cheek.withValues(alpha: 0.4);
    canvas.drawCircle(const Offset(68, 108), 13, paint);
    canvas.drawCircle(const Offset(132, 108), 13, paint);
  }

  void _drawEyes(Canvas canvas, _CharPalette palette) {
    final white  = Paint()..color = Colors.white;
    final pupil  = Paint()..color = palette.pupil;
    final shine  = Paint()..color = Colors.white;

    switch (state) {
      case CharacterState.normal:
      case CharacterState.happy:
        canvas.drawCircle(const Offset(78, 90), 9, white);
        canvas.drawCircle(const Offset(122, 90), 9, white);
        canvas.drawCircle(const Offset(80, 91), 5, pupil);
        canvas.drawCircle(const Offset(124, 91), 5, pupil);
        canvas.drawCircle(const Offset(77, 88), 2.5, shine);
        canvas.drawCircle(const Offset(121, 88), 2.5, shine);

      case CharacterState.hungry:
        canvas.drawCircle(const Offset(78, 92), 8, white);
        canvas.drawCircle(const Offset(122, 92), 8, white);
        canvas.drawCircle(const Offset(79, 93), 4.5, pupil);
        canvas.drawCircle(const Offset(123, 93), 4.5, pupil);
        canvas.drawCircle(const Offset(77, 90), 2, shine);
        canvas.drawCircle(const Offset(121, 90), 2, shine);
        // Worried brows
        final brow = Paint()
          ..color = palette.pupil.withValues(alpha: 0.5)
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(70, 82), const Offset(85, 84), brow);
        canvas.drawLine(const Offset(115, 84), const Offset(130, 82), brow);

      case CharacterState.starving:
        canvas.drawOval(Rect.fromCenter(center: const Offset(78, 91), width: 18, height: 20), white);
        canvas.drawOval(Rect.fromCenter(center: const Offset(122, 91), width: 18, height: 20), white);
        canvas.drawCircle(const Offset(78, 93), 6, pupil);
        canvas.drawCircle(const Offset(122, 93), 6, pupil);
        canvas.drawCircle(const Offset(75, 89), 2.5, shine);
        canvas.drawCircle(const Offset(119, 89), 2.5, shine);
        canvas.drawCircle(const Offset(80, 87), 1.5, shine);
        canvas.drawCircle(const Offset(124, 87), 1.5, shine);

      case CharacterState.weak:
        final line = Paint()
          ..color = palette.pupil
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawLine(const Offset(69, 90), const Offset(88, 90), line);
        canvas.drawLine(const Offset(112, 90), const Offset(131, 90), line);
    }
  }

  void _drawMouth(Canvas canvas, _CharPalette palette) {
    final stroke = Paint()
      ..color = palette.pupil
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (state) {
      case CharacterState.normal:
        final path = Path()
          ..moveTo(91, 116)
          ..cubicTo(96, 123, 104, 123, 109, 116);
        canvas.drawPath(path, stroke);

      case CharacterState.hungry:
      case CharacterState.starving:
        final fill = Paint()..color = const Color(0xFFCC6060);
        final oval = Rect.fromCenter(center: const Offset(100, 119), width: 18, height: 14);
        canvas.drawOval(oval, fill);
        canvas.drawOval(oval, stroke);

      case CharacterState.weak:
        final path = Path()
          ..moveTo(92, 119)
          ..cubicTo(97, 113, 103, 113, 108, 119);
        canvas.drawPath(path, stroke);

      case CharacterState.happy:
        final fill   = Paint()..color = Colors.white;
        final path   = Path()
          ..moveTo(86, 114)
          ..cubicTo(93, 128, 107, 128, 114, 114)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
    }
  }

  void _drawLeaf(Canvas canvas) {
    final stem = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = const Color(0xFF66BB6A);

    canvas.drawLine(const Offset(100, 26), const Offset(100, 15), stem);
    final path = Path()
      ..moveTo(100, 15)
      ..cubicTo(109, 9, 115, 14, 110, 20)
      ..cubicTo(106, 26, 100, 22, 100, 15);
    canvas.drawPath(path, leaf);
  }

  void _drawHat(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(72, 26, 56, 8), const Radius.circular(3)),
      Paint()..color = const Color(0xFFE05A20),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(82, 10, 36, 20), const Radius.circular(6)),
      Paint()..color = const Color(0xFFFF7A3D),
    );
  }

  void _drawBadge(Canvas canvas) {
    switch (state) {
      case CharacterState.starving: _drawExclamation(canvas);
      case CharacterState.hungry:   _drawQuestion(canvas);
      case CharacterState.happy:    _drawHearts(canvas);
      default: break;
    }
  }

  void _drawExclamation(Canvas canvas) {
    canvas.drawCircle(const Offset(148, 42), 14, Paint()..color = const Color(0xFFFF4444));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(145.5, 33, 5, 12), const Radius.circular(2)),
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(const Offset(148, 49.5), 2.5, Paint()..color = Colors.white);
  }

  void _drawQuestion(Canvas canvas) {
    canvas.drawCircle(const Offset(148, 42), 14, Paint()..color = const Color(0xFFFFCC33));
    final arc = Paint()
      ..color = const Color(0xFF3A2010)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final qPath = Path();
    // top curve of ?
    qPath.addArc(
      Rect.fromCenter(center: const Offset(148, 39), width: 11, height: 11),
      math.pi * 0.75,
      math.pi * 1.25,
    );
    canvas.drawPath(qPath, arc);
    // tail
    canvas.drawLine(const Offset(148, 45), const Offset(148, 48), arc);
    canvas.drawCircle(const Offset(148, 51.5), 1.8, Paint()..color = const Color(0xFF3A2010));
  }

  void _drawHearts(Canvas canvas) {
    _heart(canvas, const Offset(148, 42), 10, const Color(0xFFFF85A1));
    _heart(canvas, const Offset(162, 56),  7, const Color(0xFFFF85A1));
  }

  void _heart(Canvas canvas, Offset c, double s, Color color) {
    final path = Path()
      ..moveTo(c.dx, c.dy + s * 0.4)
      ..cubicTo(c.dx - s * 1.2, c.dy - s * 0.5,
                c.dx - s * 1.2, c.dy - s * 1.5,
                c.dx,           c.dy - s * 0.8)
      ..cubicTo(c.dx + s * 1.2, c.dy - s * 1.5,
                c.dx + s * 1.2, c.dy - s * 0.5,
                c.dx,           c.dy + s * 0.4);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MukzziPainter old) =>
      old.state != state || old.level != level;
}
