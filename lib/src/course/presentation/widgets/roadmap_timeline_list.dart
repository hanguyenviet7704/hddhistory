part of '../../course.dart';

class RoadmapTimelineList extends StatelessWidget {
  final List<RoadmapNodeEntity> nodes;
  final VoidCallback? onLessonTap;

  const RoadmapTimelineList({
    super.key,
    required this.nodes,
    this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: nodes.asMap().entries.map((entry) {
          final index = entry.key;
          final node = entry.value;
          final isFirst = index == 0;
          final isLast = index == nodes.length - 1;

          return Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : 20.h,
            ),
            child: TimelineNodeItem(
              node: node,
              isFirst: isFirst,
              isLast: isLast,
              onLessonTap: onLessonTap,
            ),
          );
        }).toList(),
      ),
    );
  }
}
