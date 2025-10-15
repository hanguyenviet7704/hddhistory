part of '../../onboard.dart';

class IntroContent extends StatelessWidget {
  final OnboardContent content;
  const IntroContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Spacer(),
          CharacterSection(content: content),
          ContentCard(content: content),
          20.verticalSpace,
        ],
      ),
    );
  }
}

class ChatArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
