part of '../../course.dart';

class RoadmapTimelineList extends StatelessWidget {
  final VoidCallback? onLessonTap;

  const RoadmapTimelineList({
    super.key,
    this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CourseCubit, CourseState, List<LessonEntity>>(
      selector: (state) => state.roadmap.lessonList,
      builder: (context, lessons) {
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

        // Sort lessons by index to ensure correct order
        final sortedLessons = [...lessons]..sort((a, b) => a.index.compareTo(b.index));

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
          child: TimelineTheme(
            data: TimelineThemeData(
              nodePosition: 0,
              indicatorPosition: 0,
              connectorTheme: ConnectorThemeData(
                thickness: 2.0,
                color: AppCustomColor.borderSecondary,
              ),
            ),
            child: FixedTimeline.tileBuilder(
              theme: TimelineThemeData(
                nodePosition: 0,
                indicatorPosition: 0,
              ),
              builder: TimelineTileBuilder(
                itemCount: sortedLessons.length,
                indicatorBuilder: (context, index) => TimelineIndicator(
                  process: sortedLessons[index].process,
                ),
                startConnectorBuilder: (context, index) => index == 0
                    ? null
                    : SolidLineConnector(
                        thickness: 2.0,
                        color: AppCustomColor.borderSecondary,
                      ),
                endConnectorBuilder: (context, index) => index == sortedLessons.length - 1
                    ? null
                    : SolidLineConnector(
                        thickness: 2.0,
                        color: AppCustomColor.borderSecondary,
                      ),
                contentsBuilder: (context, index) {
                  final isLast = index == sortedLessons.length - 1;
                  return Padding(
                    padding: EdgeInsets.only(
                      left: 16.w,
                      bottom: isLast ? 0 : 12.h,
                    ),
                    child: LessonCard(
                      lesson: sortedLessons[index],
                      onTap: onLessonTap,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
