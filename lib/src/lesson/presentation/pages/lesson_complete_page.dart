part of '../../lesson.dart';

class LessonCompletePage extends StatefulWidget {
  const LessonCompletePage({super.key});

  @override
  State<LessonCompletePage> createState() => _LessonCompletePageState();
}

class _LessonCompletePageState extends State<LessonCompletePage> with SingleTickerProviderStateMixin {
  late final AnimationController _lottieController;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Lottie.asset(
                AppAsset.lottie.congratulations,
                controller: _lottieController,
                onLoaded: (composition) {
                  _lottieController
                    ..duration = composition.duration
                    ..forward();
                },
                fit: BoxFit.cover,
                repeat: false,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          AppAsset.icons.app.icTick.path,
                          width: 50.w,
                          height: 50.w,
                        ),
                        24.verticalSpace,
                        AppText(
                          context.text.exercise.exerciseLessonCompleteTitle.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppStyle.text12.copyWith(
                            color: AppCustomColor.textTertiary,
                            fontWeight: FontWeight.w600,
                            height: 1.75,
                          ),
                        ),
                        4.verticalSpace,
                        BlocSelector<CourseLessonCubit, CourseLessonState, String>(
                          selector: (state) => state.selectedLesson.title.text,
                          builder: (context, title) {
                            return AppText(
                              title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              style: AppStyle.text20.copyWith(
                                color: AppCustomColor.textPrimary,
                                fontWeight: FontWeight.w700,
                                height: 1.5,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                LessonCompletionPrimaryButton(
                  label: context.text.exercise.exerciseCompleteLessonButton,
                  onPressed: () {
                    final bool isLastLessonInLevel = context.read<CourseRoadmapCubit>().state.isLastLessonInLevel;
                    if (isLastLessonInLevel) {
                      BadgeCompleteRoute().go(context);
                      return;
                    }
                    context.back();
                  },
                  margin: EdgeInsets.only(bottom: 16.h, top: 16.h),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
