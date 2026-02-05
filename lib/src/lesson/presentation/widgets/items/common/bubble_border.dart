part of '../../../../lesson.dart';

class BubbleBorder extends ShapeBorder {
  final bool isSender;
  final double radius;
  final double tailWidth;
  final double tailHeight;
  final double tailVerticalAlignment;
  final BorderSide borderSide; // ĐÃ THÊM

  const BubbleBorder({
    this.isSender = false,
    this.radius = 12.0,
    this.tailWidth = 10.0,
    this.tailHeight = 12.0,
    this.tailVerticalAlignment = 0.5,
    this.borderSide = BorderSide.none, // ĐÃ THÊM
  }) : assert(tailVerticalAlignment >= 0.0 && tailVerticalAlignment <= 1.0);

  @override
  EdgeInsetsGeometry get dimensions {
    // Thêm một chút padding nếu có viền,
    // để nội dung không bị viền đè lên
    final double borderWidth = borderSide.width;
    return EdgeInsets.only(
      left: (isSender ? 0 : tailWidth) + borderWidth,
      right: (isSender ? tailWidth : 0) + borderWidth,
      top: borderWidth,
      bottom: borderWidth,
    );
  }

  @override
  ui.Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // Điều chỉnh innerRect dựa trên border width
    final double borderWidth = borderSide.width;
    final Rect innerRect = Rect.fromLTRB(
      rect.left + (isSender ? 0 : tailWidth) + borderWidth,
      rect.top + borderWidth,
      rect.right - (isSender ? tailWidth : 0) - borderWidth,
      rect.bottom - borderWidth,
    );
    return ui.Path()..addRRect(ui.RRect.fromRectAndRadius(innerRect, Radius.circular(radius)));
  }

  @override
  ui.Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Rect bubbleRect;
    if (isSender) {
      bubbleRect = Rect.fromLTRB(rect.left, rect.top, rect.right - tailWidth, rect.bottom);
    } else {
      bubbleRect = Rect.fromLTRB(rect.left + tailWidth, rect.top, rect.right, rect.bottom);
    }

    double r = radius;
    double tailMinY = bubbleRect.top + r;
    double tailMaxY = bubbleRect.bottom - r;
    double tailActualY = rect.top + (rect.height * tailVerticalAlignment);

    double tailTopY = math.max(tailMinY, tailActualY - (tailHeight / 2));
    double tailBottomY = math.min(tailMaxY, tailActualY + (tailHeight / 2));

    if (tailTopY > tailBottomY - tailHeight) {
      tailBottomY = tailTopY + tailHeight;
    }
    tailActualY = (tailTopY + tailBottomY) / 2;

    ui.Path path = ui.Path();

    if (isSender) {
      // Vẽ cho Sender (đuôi bên phải)
      path.moveTo(bubbleRect.left + r, bubbleRect.top);
      path.lineTo(bubbleRect.right - r, bubbleRect.top);
      path.quadraticBezierTo(bubbleRect.right, bubbleRect.top, bubbleRect.right, bubbleRect.top + r);

      path.lineTo(bubbleRect.right, tailTopY);
      path.quadraticBezierTo(
        rect.right,
        tailActualY,
        bubbleRect.right,
        tailBottomY,
      );

      path.lineTo(bubbleRect.right, bubbleRect.bottom - r);
      path.quadraticBezierTo(bubbleRect.right, bubbleRect.bottom, bubbleRect.right - r, bubbleRect.bottom);
      path.lineTo(bubbleRect.left + r, bubbleRect.bottom);
      path.quadraticBezierTo(bubbleRect.left, bubbleRect.bottom, bubbleRect.left, bubbleRect.bottom - r);
      path.lineTo(bubbleRect.left, bubbleRect.top + r);
      path.quadraticBezierTo(bubbleRect.left, bubbleRect.top, bubbleRect.left + r, bubbleRect.top);
    } else {
      // Vẽ cho Receiver (đuôi bên trái)
      path.moveTo(bubbleRect.right - r, bubbleRect.top);
      path.lineTo(bubbleRect.left + r, bubbleRect.top);
      path.quadraticBezierTo(bubbleRect.left, bubbleRect.top, bubbleRect.left, bubbleRect.top + r);

      path.lineTo(bubbleRect.left, tailTopY);
      path.quadraticBezierTo(
        rect.left,
        tailActualY,
        bubbleRect.left,
        tailBottomY,
      );

      path.lineTo(bubbleRect.left, bubbleRect.bottom - r);
      path.quadraticBezierTo(bubbleRect.left, bubbleRect.bottom, bubbleRect.left + r, bubbleRect.bottom);
      path.lineTo(bubbleRect.right - r, bubbleRect.bottom);
      path.quadraticBezierTo(bubbleRect.right, bubbleRect.bottom, bubbleRect.right, bubbleRect.bottom - r);
      path.lineTo(bubbleRect.right, bubbleRect.top + r);
      path.quadraticBezierTo(bubbleRect.right, bubbleRect.top, bubbleRect.right - r, bubbleRect.top);
    }

    path.close();
    return path;
  }

  // --- TRIỂN KHAI PHƯƠNG THỨC PAINT ---
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // Chỉ vẽ nếu kiểu viền không phải là 'none'
    if (borderSide.style == BorderStyle.none) {
      return;
    }

    // Tạo Paint object cho đường viền
    final Paint borderPaint = Paint()
      ..style = PaintingStyle
          .stroke // Chỉ vẽ đường viền, không tô màu
      ..color = borderSide.color
      ..strokeWidth = borderSide.width;

    // Lấy đường viền bên ngoài (outer path)
    final ui.Path outerPath = getOuterPath(rect, textDirection: textDirection);

    // Vẽ đường viền
    canvas.drawPath(outerPath, borderPaint);
  }
  // ------------------------------------

  @override
  ShapeBorder scale(double t) {
    return BubbleBorder(
      isSender: isSender,
      radius: radius * t,
      tailWidth: tailWidth * t,
      tailHeight: tailHeight * t,
      tailVerticalAlignment: tailVerticalAlignment,
      borderSide: borderSide.scale(t), // Scale cả borderSide
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BubbleBorder &&
        other.isSender == isSender &&
        other.radius == radius &&
        other.tailWidth == tailWidth &&
        other.tailHeight == tailHeight &&
        other.tailVerticalAlignment == tailVerticalAlignment &&
        other.borderSide == borderSide; // So sánh borderSide
  }

  @override
  int get hashCode {
    return Object.hash(isSender, radius, tailWidth, tailHeight, tailVerticalAlignment, borderSide); // Hash borderSide
  }
}
