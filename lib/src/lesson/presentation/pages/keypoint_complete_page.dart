part of '../../lesson.dart';

class KeypointCompletePage extends StatelessWidget {
  const KeypointCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            LessonCompletionHeader(
              margin: EdgeInsets.only(
                left: 20.w,
                right: 20.w,
                top: 20.h,
              ),
              title: context.text.exercise.exerciseSubheaderLabelBuildNonverbal.toUpperCase(),
              subtitle: context.text.exercise.exerciseLessonCompleteMessage.toUpperCase(),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAsset.images.app.keypointCompleteDecoration.path,
                    width: 227.w,
                  ),
                  16.verticalSpace,
                  AppText(
                    context.text.exercise.exerciseKeypointCompleteTitle,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  if (kDebugMode) ...[
                    12.verticalSpace,
                    const LessonCompletionProgressBar(),
                  ],
                ],
              ),
            ),
            LessonCompletionPrimaryButton(
              label: context.text.exercise.exerciseCompleteKeypointSkipButton,
              onPressed: () {
                bool isAllOtherKeypointsCompleted = context.read<CourseLessonCubit>().state.isAllOtherKeypointsCompleted;
                if (!isAllOtherKeypointsCompleted) {
                  context.back();
                  return;
                }

                LessonCompleteRoute().go(context);
              },
              margin: EdgeInsets.only(bottom: 24.h, top: 12.h),
            ),
          ],
        ),
      ),
    );
  }
}
