part of '../../../../lesson.dart';

class ChatInformationWidget extends StatelessWidget {
  const ChatInformationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        children: [
          Container(
            height: 42.w,
            width: 42.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEEF2F6),
              image: DecorationImage(
                image: AssetImage(AppAsset.images.app.birdSee.path),
                fit: BoxFit.cover,
              ),
            ),
          ),
          8.horizontalSpace,
          BlocSelector<LessonCubit, LessonState, String>(
            selector: (state) => state.currentLessonSpeechBubble,
            builder: (context, speechBubble) => ExerciseChatBubble(text: speechBubble, radius: 12, tailVerticalAlignment: 0.5),
          ),
        ],
      ),
    );
  }
}

class ExerciseChatBubble extends StatelessWidget {
  final String text;
  final bool isSender;
  final double radius;
  final double tailVerticalAlignment;

  const ExerciseChatBubble({
    super.key,
    required this.text,
    this.isSender = false,
    this.radius = 20,
    this.tailVerticalAlignment = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: 1.sw * 0.75,
      ),
      decoration: ShapeDecoration(
        shape: BubbleBorder(
          isSender: isSender,
          radius: radius,
          tailWidth: 20,
          tailHeight: 15,
          tailVerticalAlignment: tailVerticalAlignment,
          borderSide: BorderSide(color: Color(0xFFE3E8EF), width: 2.w),
        ),
        color: isSender ? Colors.blue[100] : Color(0xFFF5F7FB),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: AppText(text, style: AppStyle.textBold14, maxLines: 10),
    );
  }
}
