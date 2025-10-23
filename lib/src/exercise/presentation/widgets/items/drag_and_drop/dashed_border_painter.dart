part of '../../../../exercise.dart';

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dashWidth;
  final double dashSpace;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 2,
    this.dashWidth = 6,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const radius = 8.0;
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(radius));

    final path = ui.Path()..addRRect(rrect);

    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  ui.Path _createDashedPath(ui.Path source) {
    final path = ui.Path();
    final metrics = source.computeMetrics();

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;

      while (distance < metric.length) {
        final length = draw ? dashWidth : dashSpace;
        final nextDistance = distance + length;

        if (draw) {
          path.addPath(
            metric.extractPath(distance, nextDistance.clamp(0, metric.length)),
            Offset.zero,
          );
        }

        distance = nextDistance;
        draw = !draw;
      }
    }

    return path;
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth || oldDelegate.dashWidth != dashWidth || oldDelegate.dashSpace != dashSpace;
  }
}
