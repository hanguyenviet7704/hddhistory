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
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'output-practice-intro-sheet',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (dialogContext, _, _) => OutputPracticeIntroSheet(
        lesson: lesson,
        onStart: () {
          didStart = true;
          dialogContext.pop();
          onStart();
        },
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
    if (!didStart) {
      onDismissed?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = context.l10n.outputPractice;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.pop(),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                  child: const ColoredBox(
                    color: Color(0x99364152),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                    padding: EdgeInsets.fromLTRB(
                      20.w,
                      20.h,
                      20.w,
                      (bottomInset > 0 ? bottomInset : 0) + 20.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(
                          lesson.title.text,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: AppStyle.textBold24.copyWith(
                            color: AppCustomColor.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        4.verticalSpace,
                        AppText(
                          copy.practiceLabel.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: AppStyle.text12.copyWith(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppCustomColor.textTertiary,
                            height: 1.75,
                          ),
                        ),
                        12.verticalSpace,
                        AppText(
                          lesson.description.text,
                          maxLines: 100,
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
                          child: Text(
                            copy.startPracticeButton,
                            textAlign: TextAlign.center,
                            style: AppStyle.textBold16.copyWith(
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
