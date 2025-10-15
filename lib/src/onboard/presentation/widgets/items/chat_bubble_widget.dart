part of '../../../onboard.dart';

class ChatBubbleWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? iconPath;

  const ChatBubbleWidget({
    super.key,
    required this.title,
    required this.subtitle,
    this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Main chat bubble content
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: const Color(0xFFE3E8EF),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (iconPath != null) ...[
                _buildIcon(),
                8.verticalSpace,
              ],
              _buildTextContent(),
            ],
          ),
        ),
        // Chat bubble arrow/tail
        _buildArrow(),
      ],
    );
  }

  Widget _buildIcon() {
    return SizedBox(
      width: 32.w,
      height: 32.h,
      child: iconPath != null
          ? SvgPicture.asset(
              iconPath!,
              width: 32.w,
              height: 32.h,
              fit: BoxFit.contain,
            )
          : Icon(
              Icons.star,
              color: const Color(0xFF554FF0),
              size: 32.w,
            ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppStyle.text20.copyWith(
            fontWeight: FontWeight.w500,
            color: const Color(0xFF0D121C),
            height: 1.5,
          ),
          maxLines: 2,
        ),
        8.verticalSpace,
        AppText(
          subtitle,
          style: AppStyle.text16.copyWith(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF364152),
            height: 1.5,
          ),
          maxLines: 2,
        ),
      ],
    );
  }

  Widget _buildArrow() {
    return Container(
      height: 15.h,
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      alignment: Alignment.centerLeft,
      child: CustomPaint(
        size: Size(25.w, 16.h),
        painter: _ChatBubbleArrowPainter(),
      ),
    );
  }
}

class _ChatBubbleArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFFE3E8EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Create triangle path (pointing down)
    final path = ui.Path()
      ..moveTo(size.width / 2, size.height) // Bottom point
      ..lineTo(0, 0) // Top left
      ..lineTo(size.width, 0) // Top right
      ..close();

    // Draw fill
    canvas.drawPath(path, paint);
    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
