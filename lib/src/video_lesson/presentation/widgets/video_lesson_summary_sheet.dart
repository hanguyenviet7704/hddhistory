part of '../../video_lesson.dart';

class VideoLessonSummarySheet extends StatelessWidget {
  const VideoLessonSummarySheet({
    super.key,
    required this.summary,
    required this.onClose,
    required this.onScroll,
  });

  final String summary;
  final VoidCallback onClose;
  final VoidCallback onScroll;

  @override
  Widget build(BuildContext context) {
    final overview = _summaryOverview(summary);
    final keyPoints = _summaryKeyPoints(summary);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        height: 406.h,
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
        ),
        child: Column(
          children: [
            6.verticalSpace,
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 16.h),
              child: Row(
                children: [
                  Expanded(
                    child: AppText(
                      context.l10n.videoLesson.summaryTitle,
                      style: AppStyle.textBold18.copyWith(
                        color: AppCustomColor.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 24.r,
                      color: AppCustomColor.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  if (notification is ScrollUpdateNotification && notification.scrollDelta != null && notification.scrollDelta != 0) {
                    onScroll();
                  }
                  return false;
                },
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _VideoLessonSummarySection(
                        title: context.l10n.videoLesson.summaryOverviewTitle,
                        child: AppText(
                          overview,
                          maxLines: 100,
                          style: AppStyle.text14.copyWith(
                            color: AppCustomColor.textSecondary,
                            height: 1.75,
                          ),
                        ),
                      ),
                      20.verticalSpace,
                      _VideoLessonSummarySection(
                        title: context.l10n.videoLesson.summaryKeyPointsTitle,
                        child: Column(
                          children: keyPoints
                              .map(
                                (item) => Padding(
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 8.h),
                                        child: Container(
                                          width: 6.r,
                                          height: 6.r,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF4B44CA),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                      10.horizontalSpace,
                                      Expanded(
                                        child: AppText(
                                          item,
                                          maxLines: 10,
                                          style: AppStyle.text14.copyWith(
                                            color: AppCustomColor.textSecondary,
                                            height: 1.75,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom),
          ],
        ),
      ),
    );
  }
}

class _VideoLessonSummarySection extends StatelessWidget {
  const _VideoLessonSummarySection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          title,
          style: AppStyle.textBold16.copyWith(
            color: AppCustomColor.textPrimary,
            height: 1.5,
          ),
        ),
        12.verticalSpace,
        child,
      ],
    );
  }
}

String _summaryOverview(String rawSummary) {
  final trimmed = rawSummary.trim();
  if (trimmed.isEmpty) return '-';
  final paragraphs = trimmed.split(RegExp(r'\n{2,}')).where((item) => item.trim().isNotEmpty).toList();
  return paragraphs.isEmpty ? trimmed : paragraphs.first.trim();
}

List<String> _summaryKeyPoints(String rawSummary) {
  final trimmed = rawSummary.trim();
  if (trimmed.isEmpty) return const ['-'];

  final explicitBullets = trimmed.split('\n').map((line) => line.replaceFirst(RegExp(r'^[\-\*\u2022]\s*'), '').trim()).where((line) => line.isNotEmpty).toList();

  if (explicitBullets.length > 1) return explicitBullets.take(5).toList();

  final sentences = trimmed.split(RegExp(r'(?<=[.!?])\s+')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

  return (sentences.isEmpty ? [trimmed] : sentences).take(5).toList();
}
