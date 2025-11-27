part of '../../../../lesson.dart';

class LessonProgressBar extends StatelessWidget {
  const LessonProgressBar({
    super.key,
  });

  void _onCloseTap(BuildContext context) {
    bool isShowResultOverlay = AppDI.injector.get<LessonCubit>().isShowResultOverlay;
    if (isShowResultOverlay) return;
    
    ClosePopupLesson.show(
      context,
      onQuit: () {
        context.back();
        context.back();
      },
      onKeepLearning: () {
        context.back();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        20.horizontalSpace,
        InkWell(
          onTap: () => _onCloseTap(context),
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

        // BlocSelector<LessonCubit, LessonState, LearningItemType>(
        //   selector: (state) => state.currentLearningItem.type,
        //   builder: (context, learningItemType) {
        //     if (learningItemType != LearningItemType.roleplay) {
        //       return const SizedBox.shrink();
        //     }

        //     return Row(
        //       children: [
        //         20.horizontalSpace,
        //         LessonTimeBanner(onDone: () => context.read<ExerciseCubit>().nextQuestion()),
        //       ],
        //     );
        //   },
        // ),
        20.horizontalSpace,
      ],
    );
  }
}
