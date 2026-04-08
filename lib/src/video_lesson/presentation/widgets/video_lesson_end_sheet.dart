part of '../../video_lesson.dart';

class VideoLessonEndSheet extends StatelessWidget {
  const VideoLessonEndSheet({
    super.key,
    required this.lesson,
    required this.isSubmitting,
    required this.errorMessage,
    required this.onSubmit,
  });

  final LessonEntity lesson;
  final bool isSubmitting;
  final String? errorMessage;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: 335.w),
              padding: EdgeInsets.fromLTRB(20.w, 52.h, 20.w, 20.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x29000000),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    context.l10n.videoLesson.lessonCompleteTitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.textBold20.copyWith(
                      color: AppCustomColor.textPrimary,
                      height: 1.5,
                    ),
                  ),
                  4.verticalSpace,
                  AppText(
                    context.l10n.videoLesson.lessonCompleteSubtitle,
                    textAlign: TextAlign.center,
                    style: AppStyle.text14.copyWith(
                      color: AppCustomColor.textSecondary,
                      height: 1.75,
                    ),
                  ),
                  if ((errorMessage ?? '').isNotEmpty) ...[
                    12.verticalSpace,
                    AppText(
                      errorMessage!,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      style: AppStyle.text12.copyWith(
                        color: AppCustomColor.errorRed,
                        height: 1.5,
                      ),
                    ),
                  ],
                  24.verticalSpace,
                  AppButton.primary(
                    onPressed: isSubmitting ? null : onSubmit,
                    fullWidthBtn: true,
                    disabled: isSubmitting,
                    height: 54.h,
                    borderRadius: BorderRadius.circular(1000.r),
                    child: isSubmitting
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : AppText(
                            context.l10n.videoLesson.markAsCompleteButton,
                            style: AppStyle.textBold16.copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -40.h,
              child: AppAsset.images.app.target.image(
                width: 90.w,
                height: 90.w,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
