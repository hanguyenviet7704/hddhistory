part of '../../../../lesson.dart';

class LessonNavigationPopup extends StatelessWidget {
  const LessonNavigationPopup({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LessonNavigationPopup',
      barrierColor: AppCustomColor.scrimOverlay,
      useRootNavigator: false,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: const LessonNavigationPopup(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.pop(),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 315.w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppCustomColor.backgroundWhite,
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppCustomColor.borderDefault,
                          blurRadius: 8.r,
                          offset: Offset.zero,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 330.h,
                            width: double.infinity,
                            child: ColoredBox(
                              color: AppCustomColor.brandPrimary50,
                              child: Lottie.asset(
                                AppAsset.lottie.scrollGuide,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 36.h),
                            child: Column(
                              children: [
                                AppText(
                                  context.text.lesson.navigationPopupTitle,
                                  textAlign: TextAlign.center,
                                  style: AppStyle.text20.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppCustomColor.textPrimary,
                                    height: 1.5,
                                  ),
                                  maxLines: 2,
                                ),
                                8.verticalSpace,
                                _NavigationInstructionLine(
                                  boldText: context.text.lesson.navigationPopupContinueBold,
                                  regularText: context.text.lesson.navigationPopupContinueRest,
                                ),
                                _NavigationInstructionLine(
                                  boldText: context.text.lesson.navigationPopupScrollBold,
                                  regularText: context.text.lesson.navigationPopupScrollRest,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                40.verticalSpace,
                AppText(
                  context.text.lesson.navigationPopupTapToContinue,
                  textAlign: TextAlign.center,
                  style: AppStyle.text16.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppCustomColor.textWhite,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationInstructionLine extends StatelessWidget {
  final String boldText;
  final String regularText;

  const _NavigationInstructionLine({
    required this.boldText,
    required this.regularText,
  });

  @override
  Widget build(BuildContext context) {
    final TextStyle baseStyle = AppStyle.text14.copyWith(
      color: AppCustomColor.textSecondary,
      height: 1.75,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: boldText,
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $regularText', style: baseStyle),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
