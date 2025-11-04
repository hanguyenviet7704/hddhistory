part of '../../course.dart';

class TimelineNodeItem extends StatelessWidget {
  final RoadmapNodeEntity node;
  final bool isFirst;
  final bool isLast;
  final VoidCallback? onLessonTap;

  const TimelineNodeItem({
    super.key,
    required this.node,
    this.isFirst = false,
    this.isLast = false,
    this.onLessonTap,
  });

  ProcessEnum _getNodeStatus() {
    // Check if all lessons in this node are done
    final allLessons = [
      node.entrance,
      ...node.lessons,
      node.output,
    ].where((l) => l.id.isNotEmpty).toList();

    if (allLessons.isEmpty) return ProcessEnum.notStarted;

    final allDone = allLessons.every((lesson) => lesson.process == ProcessEnum.done);
    final anyInProgress = allLessons.any((lesson) => lesson.process == ProcessEnum.inProgress);

    if (allDone) return ProcessEnum.done;
    if (anyInProgress) return ProcessEnum.inProgress;
    return ProcessEnum.notStarted;
  }

  @override
  Widget build(BuildContext context) {
    final nodeStatus = _getNodeStatus();
    final allLessons = [
      if (node.entrance.id.isNotEmpty) node.entrance,
      ...node.lessons,
      if (node.output.id.isNotEmpty) node.output,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Node title
        Padding(
          padding: EdgeInsets.only(left: 40.w, bottom: 12.h),
          child: AppText(
            node.title.text,
            style: AppStyle.text20.copyWith(
              fontWeight: FontWeight.w600,
              color: AppCustomColor.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // Lessons with timeline
        ...allLessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final isLastLesson = index == allLessons.length - 1;

          return _TimelineLessonItem(
            lesson: lesson,
            nodeStatus: nodeStatus,
            isLastLesson: isLastLesson && isLast,
            onTap: onLessonTap,
          );
        }),
      ],
    );
  }
}

class _TimelineLessonItem extends StatelessWidget {
  final LessonEntity lesson;
  final ProcessEnum nodeStatus;
  final bool isLastLesson;
  final VoidCallback? onTap;

  const _TimelineLessonItem({
    required this.lesson,
    required this.nodeStatus,
    required this.isLastLesson,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: 24.w,
            child: Column(
              children: [
                // Node indicator circle
                Container(
                  width: 24.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: _getNodeCircleColor(),
                    shape: BoxShape.circle,
                    border: lesson.process == ProcessEnum.inProgress
                        ? Border.all(
                            color: AppCustomColor.brandPrimary,
                            width: 3.w,
                          )
                        : null,
                  ),
                  child: _getNodeIcon(),
                ),
                // Connector line
                if (!isLastLesson)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      color: AppCustomColor.borderSecondary,
                    ),
                  ),
              ],
            ),
          ),
          16.horizontalSpace,
          // Lesson card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLastLesson ? 0 : 12.h),
              child: LessonCard(
                lesson: lesson,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getNodeCircleColor() {
    switch (lesson.process) {
      case ProcessEnum.done:
        return AppCustomColor.brandPrimary;
      case ProcessEnum.inProgress:
        return AppCustomColor.backgroundWhite;
      case ProcessEnum.notStarted:
        return AppCustomColor.borderSecondary;
    }
  }

  Widget? _getNodeIcon() {
    if (lesson.process == ProcessEnum.done) {
      return Icon(
        Icons.check_rounded,
        size: 16.w,
        color: AppCustomColor.backgroundWhite,
      );
    } else if (lesson.process == ProcessEnum.notStarted) {
      return Icon(
        Icons.lock_rounded,
        size: 14.w,
        color: AppCustomColor.textQuaternary,
      );
    }
    return null; // For in progress, just show empty circle with border
  }
}
