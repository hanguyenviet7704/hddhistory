part of '../../onboard.dart';

class CharacterSection extends StatelessWidget {
  final OnboardIntroEntity content;
  const CharacterSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChatBubble(message: content.title.text),
          32.verticalSpace,
          CharacterIllustration(
            iconPath: content.image,
          ),
        ],
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String message;
  const ChatBubble({
    super.key,
    this.message = '',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.w,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10.r),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34C6AA).withValues(alpha: 0.12),
                  offset: const Offset(0, 4),
                  blurRadius: 24,
                ),
              ],
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: child,
                );
              },
              child: AppText(
                message,
                key: ValueKey<String>(message),
                style: AppStyle.text16.copyWith(
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF364152),
                  height: 1.75,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          MessageArrowDown(),
        ],
      ),
    );
  }
}

class CharacterIllustration extends StatelessWidget {
  final String iconPath;
  const CharacterIllustration({super.key, this.iconPath = ''});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: DCachedImage(
          key: ValueKey<String>(iconPath),
          url: iconPath,
          width: 210.w,
          // width: iconPath.contains('happy') ? 120.w : 210.w,
        ),
      ),
    );
  }
}

class MessageArrowDown extends StatelessWidget {
  const MessageArrowDown({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280.w,
      height: 10.h,
      child: Center(
        child: Transform.rotate(
          angle: 3.14159, // 180 degrees
          child: SizedBox(
            width: 25.865.w,
            height: 16.h,
            child: CustomPaint(
              painter: ChatArrowPainter(),
            ),
          ),
        ),
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
