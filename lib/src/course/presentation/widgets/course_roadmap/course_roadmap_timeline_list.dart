part of '../../../course.dart';

class CourseRoadmapTimeline extends StatelessWidget {
  final List<LessonEntity> lessons;
  const CourseRoadmapTimeline({
    required this.lessons,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (lessons.isEmpty) {
      return Container(
        padding: EdgeInsets.all(32.w),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Center(
          child: AppText(
            'No roadmap available',
            style: AppStyle.text14.copyWith(
              color: AppCustomColor.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppCustomColor.borderDefault,
            blurRadius: 4,
            offset: const Offset(0, 0),
          ),
        ],
      ),

      child: Column(
        children: List.generate(lessons.length, (index) {
          final lesson = lessons[index];
          final isFirst = index == 0;
          final isLast = index == lessons.length - 1;

          return TimelineTile(
            isFirst: isFirst,
            isLast: isLast,
            alignment: TimelineAlign.start,
            indicatorStyle: IndicatorStyle(
              width: 32.w,
              height: 32.w,
              padding: EdgeInsets.zero,
              indicator: TimelineIndicator(progess: lesson.progess),
              // indicator: TimelineIndicator(process: ProcessEnum.done),
            ),
            beforeLineStyle: LineStyle(
              color: AppCustomColor.borderSecondary,
              thickness: 2.0,
            ),
            afterLineStyle: LineStyle(
              color: AppCustomColor.borderSecondary,
              thickness: 2.0,
            ),
            endChild: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                bottom: 8.h,
                top: 8.h,
              ),
              child: LessonCard(lesson: lesson),
            ),
          );
        }),
      ),
    );
  }
}
