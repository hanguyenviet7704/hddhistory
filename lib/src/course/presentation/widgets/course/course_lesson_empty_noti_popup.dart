part of '../../../course.dart';

class CourseLessonEmptyNotiPopup extends StatelessWidget {
  const CourseLessonEmptyNotiPopup({super.key});

  static void show(BuildContext context) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'courseLessonEmptyNotiPopup',
      barrierColor: Colors.black.op(0.6),
      useRootNavigator: false,
      routeSettings: const RouteSettings(name: RouteNamed.courseLessonEmptyNotiPopup),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, _, _) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            child: const CourseLessonEmptyNotiPopup(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: AppCustomColor.backgroundWhite,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.lesson.emptyPopupTitle,
                    style: AppStyle.textBold20.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                  8.verticalSpace,
                  AppText(
                    context.l10n.lesson.emptyPopupDescription,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.75,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                  24.verticalSpace,
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      height: 54.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppCustomColor.brandPrimary,
                        borderRadius: BorderRadius.circular(1000.r),
                      ),
                      alignment: Alignment.center,
                      child: AppText(
                        context.l10n.lesson.emptyPopupCta,
                        style: AppStyle.text16.copyWith(
                          color: AppCustomColor.textWhite,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -44.h,
              child: AppAsset.icons.app.icDanger.image(
                width: 83.w,
                height: 72.h,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
