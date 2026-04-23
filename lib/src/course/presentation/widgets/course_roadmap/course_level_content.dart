part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  final bool enableSequentialUnlock;
  final Set<String> lockedLessonKeys;
  final CompletedLevelAdditionalContentRequestPromptStatus additionalContentRequestStatus;
  final bool isSubmittingAdditionalContentRequest;
  final Future<bool> Function()? onNoAdditionalContentRequest;
  final VoidCallback? onYesAdditionalContentRequest;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
    this.enableSequentialUnlock = true,
    this.lockedLessonKeys = const {},
    this.additionalContentRequestStatus = CompletedLevelAdditionalContentRequestPromptStatus.hidden,
    this.isSubmittingAdditionalContentRequest = false,
    this.onNoAdditionalContentRequest,
    this.onYesAdditionalContentRequest,
  });

  List<bool> get _sequentialUnlockFlags {
    if (!enableSequentialUnlock) return List<bool>.filled(roadmapLevel.nodes.length, false);
    return roadmapLevel.sequentialUnlockFlags;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CourseRoadmapHeaderCard(roadmapLevel: roadmapLevel),
        16.verticalSpace,
        ...roadmapLevel.nodes.asMap().entries.map((entry) {
          return RoadmapNodeItem(
            node: entry.value,
            enableSequentialUnlock: _sequentialUnlockFlags.elementAt(entry.key),
            lockedLessonKeys: lockedLessonKeys,
          );
        }),
        if (additionalContentRequestStatus.isVisible)
          CompletedLevelAdditionalContentRequestCard(
            level: roadmapLevel.level,
            status: additionalContentRequestStatus,
            isSubmitting: isSubmittingAdditionalContentRequest,
            onNoSelected: onNoAdditionalContentRequest,
            onYesSelected: onYesAdditionalContentRequest,
          ),

        // CourseRoadmapTimeline(
        //   lessons: roadmapLevel.appProgressLessons(usingAppProgressLessons),
        //   courseLevel: roadmapLevel.level,
        //   lockedLessonStartIndex: lockedLessonStartIndex,
        // ),
      ],
    );
  }
}
