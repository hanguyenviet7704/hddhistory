part of '../../output_practice.dart';

class OutputPracticeIntroSheet extends StatelessWidget {
  const OutputPracticeIntroSheet({
    super.key,
    required this.lesson,
    required this.onStart,
  });

  final LessonEntity lesson;
  final VoidCallback onStart;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required VoidCallback onStart,
    VoidCallback? onDismissed,
  }) async {
    var didStart = false;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x99364152),
      builder: (sheetContext) => OutputPracticeIntroSheet(
        lesson: lesson,
        onStart: () {
          didStart = true;
          sheetContext.pop();
          onStart();
        },
      ),
    );
    if (!didStart) {
      onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.outputPractice;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            6.verticalSpace,
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
              ),
              padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 20.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    lesson.title.text,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold24.copyWith(color: AppCustomColor.textPrimary),
                  ),
                  4.verticalSpace,
                  AppText(
                    copy.practiceLabel.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: AppStyle.text12.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: AppCustomColor.textTertiary,
                      height: 1.75,
                    ),
                  ),
                  12.verticalSpace,
                  AppText(
                    lesson.description.text,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.75,
                    ),
                  ),
                  40.verticalSpace,
                  AppButton.primary(
                    onPressed: onStart,
                    fullWidthBtn: true,
                    height: 54.h,
                    borderRadius: BorderRadius.circular(1000.r),
                    child: AppText(
                      copy.startPracticeButton,
                      style: AppStyle.textBold16.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
