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
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const LessonCompletionHeroCard(),
                  32.verticalSpace,
                  AppText(
                    'Keypoint complete!',
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.4,
                    ),
                  ),
                  12.verticalSpace,
                  const LessonCompletionProgressBar(progress: 0.68),
                ],
              ),
            ),
            LessonCompletionPrimaryButton(
              label: 'Continue',
              onPressed: () => context.back(),
              margin: EdgeInsets.only(bottom: 24.h, top: 12.h),
            ),
          ],
        ),
      ),
    );
  }
}
