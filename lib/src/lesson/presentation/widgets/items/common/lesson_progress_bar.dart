part of '../../../../lesson.dart';

class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        20.horizontalSpace,
        InkWell(
          onTap: () => ClosePopupLesson.show(
            context,
            onQuit: () {
              context.back();
              context.back();
            },
            onKeepLearning: () {
              context.back();
            },
          ),
          child: Icon(
            Icons.close_rounded,
            color: const Color(0xFF0D121C), // Brand/Brand/Primary/300
            size: 20.sp,
          ),
        ),
        10.horizontalSpace,
        Expanded(
          child: BlocSelector<LessonCubit, LessonState, double>(
            selector: (state) => state.progress,
            builder: (context, progress) {
              return LinearPercentIndicator(
                animation: true,
                animationDuration: 500,
                animateFromLastPercent: true,
                lineHeight: 10.h,
                percent: progress,
                backgroundColor: const Color(0xFFE3E8EF), // Neutral/200
                progressColor: const Color(0xFF0D121C), // Brand/Brand/Primary/300
                barRadius: Radius.circular(30.r),
                padding: EdgeInsets.zero,
              );
            },
          ),
        ),
        20.horizontalSpace,
      ],
    );
  }
}
