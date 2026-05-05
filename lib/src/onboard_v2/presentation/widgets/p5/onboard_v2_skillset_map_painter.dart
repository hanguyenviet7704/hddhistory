part of '../../../onboard_v2.dart';

class OnboardV2SkillsetMapPainter extends CustomPainter {
  const OnboardV2SkillsetMapPainter();

  static const _designWidth = 335.0;
  static const _hexLeft = 55.57867431640625;
  static const _hexTop = 68.26382446289062;
  static const _hexWidth = 223.84390258789062;
  static const _hexHeight = 258.47265625;
  static const _ringScales = [1.0, 0.7835, 0.5224, 0.2612];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / _designWidth;
    final bounds = Rect.fromLTWH(_hexLeft * scale, _hexTop * scale, _hexWidth * scale, _hexHeight * scale);
    final center = bounds.center;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 * scale
      ..color = AppCustomColor.backgroundBrandSoft;

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    for (final ringScale in _ringScales) {
      final path = _hexPath(center, bounds.height * ringScale / 2);
      if (ringScale == 1.0) {
        canvas.drawShadow(path, AppCustomColor.brandPrimary.op(0.08), 24 * scale, false);
        canvas.drawPath(path, fill);
      }
      canvas.drawPath(path, paint);
    }
  }

  ui.Path _hexPath(Offset center, double radius) {
    final path = ui.Path();
    for (var i = 0; i < 6; i++) {
      final angle = -math.pi / 2 + i * math.pi / 3;
      final point = Offset(center.dx + math.cos(angle) * radius, center.dy + math.sin(angle) * radius);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
