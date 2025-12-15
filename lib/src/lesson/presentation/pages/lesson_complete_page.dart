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
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 28.h, bottom: 16.h),
              child: BlocSelector<LessonCubit, LessonState, String>(
                selector: (state) => state.currentLearningItem.title.text,
                builder: (context, title) {
                  return AppText(
                    title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.6,
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 240.h,
                    width: 240.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Lottie.asset(
                          AppAsset.lottie.congratulations,
                          controller: _lottieController,
                          onLoaded: (composition) {
                            _lottieController
                              ..duration = composition.duration
                              ..forward();
                          },
                          repeat: false,
                        ),
                        Container(
                          width: 64.w,
                          height: 64.w,
                          decoration: BoxDecoration(
                            color: AppCustomColor.successGreen,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppCustomColor.successGreen.op(0.3),
                                blurRadius: 24,
                                offset: Offset(0, 16.h),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.check_rounded,
                            size: 32.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  24.verticalSpace,
                  AppText(
                    context.text.exercise.exerciseLessonCompleteTitle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  8.verticalSpace,
                  AppText(
                    context.text.exercise.exerciseLessonCompleteMessage,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textTertiary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            LessonCompletionPrimaryButton(
              label: context.text.exercise.exerciseCompleteLessonButton,
              onPressed: () => context.back(),
              margin: EdgeInsets.only(bottom: 24.h, top: 12.h),
            ),
          ],
        ),
      ),
    );
  }
}
