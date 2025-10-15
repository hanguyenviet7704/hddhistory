part of '../../onboard.dart';

class CharacterSection extends StatelessWidget {
  final OnboardContent content;
  const CharacterSection({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChatBubble(message: content.chatMessage),
          32.verticalSpace,
          CharacterIllustration(
            iconPath: content.iconPath,
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
                style: AppStyle.text14.copyWith(
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF364152),
                  height: 1.75,
                ),
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _buildChatArrow(),
        ],
      ),
    );
  }

  Widget _buildChatArrow() {
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

class CharacterIllustration extends StatelessWidget {
  final String iconPath;
  const CharacterIllustration({super.key, this.iconPath = ''});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210.45.w,
      height: 160.h,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: SizedBox(
            key: ValueKey<String>(iconPath),
            width: 205.29.w,
            height: 201.802.h,
            child: Image.asset(
              iconPath,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
