part of '../../../../lesson.dart';


/// Custom thumb shape for the audio slider
class CustomSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double borderWidth;
  final Color thumbColor;
  final Color borderColor;

  const CustomSliderThumbShape({
    this.thumbRadius = 12.0,
    this.borderWidth = 3.0,
    this.thumbColor = Colors.white,
    this.borderColor = const Color(0xFF554FF0),
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Draw outer border circle
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, borderPaint);

    // Draw inner white circle
    final thumbPaint = Paint()
      ..color = thumbColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius - borderWidth, thumbPaint);
  }
}
