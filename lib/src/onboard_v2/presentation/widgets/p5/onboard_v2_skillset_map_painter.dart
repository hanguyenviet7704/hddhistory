part of '../../../onboard_v2.dart';

class OnboardV2SkillsetMapPainter extends CustomPainter {
  const OnboardV2SkillsetMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Rect.fromLTWH(55.6.w, 68.3.h, 223.8.w, 258.5.h);
    final center = bounds.center;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFE4E2FD).withValues(alpha: 0.55);

    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.45);

    for (final scale in [1.0, 0.72, 0.44, 0.18]) {
      final path = _hexPath(center, bounds.width * scale / 2, bounds.height * scale / 2);
      if (scale == 1.0) canvas.drawPath(path, fill);
      canvas.drawPath(path, paint);
    }
  }

  ui.Path _hexPath(Offset center, double rx, double ry) {
    final path = ui.Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 6 + i * math.pi / 3;
      final point = Offset(center.dx + math.cos(angle) * rx, center.dy + math.sin(angle) * ry);
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
