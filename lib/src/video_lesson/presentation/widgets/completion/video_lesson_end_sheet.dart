part of '../../../video_lesson.dart';

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
    return _VideoLessonAnimatedEntrance(
      beginOffset: Offset(0, 26.h),
      beginScale: 0.94,
      curve: _videoLessonSpringCurve,
      child: Center(
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
                      child: AnimatedSwitcher(
                        duration: _videoLessonFastAnimationDuration,
                        switchInCurve: _videoLessonEntranceCurve,
                        switchOutCurve: _videoLessonExitCurve,
                        transitionBuilder: (child, animation) => FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
                            child: child,
                          ),
                        ),
                        child: isSubmitting
                            ? const SizedBox.square(
                                key: ValueKey('video-lesson-complete-loading'),
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : AppText(
                                context.l10n.videoLesson.markAsCompleteButton,
                                key: const ValueKey('video-lesson-complete-label'),
                                style: AppStyle.textBold16.copyWith(color: Colors.white),
                                textAlign: TextAlign.center,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -40.h,
                child: _VideoLessonAnimatedEntrance(
                  beginScale: 0.72,
                  delay: const Duration(milliseconds: 80),
                  curve: _videoLessonSpringCurve,
                  child: AppAsset.images.app.target.image(
                    width: 90.w,
                    height: 90.w,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
