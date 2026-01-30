part of '../../../course.dart';

class RoadmapNodeItem extends StatelessWidget {
  final RoadmapNodeEntity node;

  const RoadmapNodeItem({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    if (node.lessonsList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadmapSessionHeader(
          title: node.title,
          description: node.description,
        ),

        RoadmapNodeTimeline(
          items: node.lessonsList,
        ),
        32.verticalSpace,
      ],
    );
  }
}
