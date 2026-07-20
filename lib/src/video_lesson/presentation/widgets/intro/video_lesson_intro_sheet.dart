part of '../../../video_lesson.dart';

class VideoLessonIntroSheet extends StatelessWidget {
  const VideoLessonIntroSheet({
    super.key,
    required this.lesson,
    required this.onClose,
    required this.onStart,
  });

  final LessonEntity lesson;
  final VoidCallback onClose;
  final VoidCallback onStart;

  static Future<void> show(
    BuildContext context, {
    required LessonEntity lesson,
    required String nodeId,
    required CourseLessonTrackingData? trackingData,
    required VoidCallback onStart,
  }) => _showVideoLessonIntroSheet(
    context,
    lesson: lesson,
    nodeId: nodeId,
    trackingData: trackingData,
    onStart: onStart,
  );

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final durationText = lesson.estimateCompleTime.text.isNotEmpty ? lesson.estimateCompleTime.text : context.l10n.videoLesson.videoDurationFallback;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onClose,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(color: const Color(0x99364152)),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if ((details.primaryVelocity ?? 0) > 500) {
                  onClose();
                }
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 6.h, 20.w, 20.h + bottomInset),
                decoration: BoxDecoration(
                  color: AppCustomColor.backgroundWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.62),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 50.w,
                            height: 5.h,
                            decoration: BoxDecoration(
                              color: AppCustomColor.backgroundWhite,
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                          ),
                        ),
                        16.verticalSpace,
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              AppHaptic.select();
                              onClose();
                            },
                            child: Padding(
                              padding: EdgeInsets.all(4.r),
                              child: SvgPicture.asset(
                                AppAsset.svg.app.icClose,
                                width: 20.w,
                                height: 20.w,
                                colorFilter: const ColorFilter.mode(AppCustomColor.textPrimary, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                        AppText(
                          lesson.title.text,
                          maxLines: 4,
                          textAlign: TextAlign.center,
                          style: AppStyle.textBold24.copyWith(
                            color: AppCustomColor.textPrimary,
                            height: 1.5,
                          ),
                        ),
                        4.verticalSpace,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AppText(
                              context.l10n.videoLesson.videoTypeLabel,
                              style: AppStyle.text12.copyWith(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppCustomColor.textTertiary,
                                height: 1.75,
                              ),
                            ),
                            12.horizontalSpace,
                            Container(
                              width: 4.w,
                              height: 4.w,
                              decoration: const ShapeDecoration(
                                color: AppCustomColor.textTertiary,
                                shape: OvalBorder(),
                              ),
                            ),
                            12.horizontalSpace,
                            SvgPicture.asset(
                              AppAsset.svg.app.icClock,
                              width: 16.w,
                              height: 16.w,
                              colorFilter: const ColorFilter.mode(AppCustomColor.textTertiary, BlendMode.srcIn),
                            ),
                            8.horizontalSpace,
                            AppText(
                              durationText.toUpperCase(),
                              style: AppStyle.text12.copyWith(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: AppCustomColor.textTertiary,
                                height: 1.75,
                              ),
                            ),
                          ],
                        ),
                        12.verticalSpace,
                        AppText(
                          lesson.description.text,
                          maxLines: 20,
                          textAlign: TextAlign.center,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
                        ),
                        32.verticalSpace,
                        AppButton.primary(
                          onPressed: onStart,
                          fullWidthBtn: true,
                          height: 54.h,
                          borderRadius: BorderRadius.circular(1000.r),
                          child: AppText(
                            context.l10n.videoLesson.startWatchingButton,
                            style: AppStyle.textBold16.copyWith(
                              color: AppCustomColor.textWhite,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
