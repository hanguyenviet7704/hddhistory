part of '../../course.dart';

class RoadmapTimelineList extends StatelessWidget {
  final List<LessonEntity> lessons;
  final VoidCallback? onLessonTap;

  const RoadmapTimelineList({
    super.key,
    required this.lessons,
    this.onLessonTap,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sortedLessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          final isLast = index == sortedLessons.length - 1;

          return TimelineLessonItem(
            lesson: lesson,
            isLast: isLast,
            onTap: onLessonTap,
          );
        }).toList(),
      ),
    );
  }
}
