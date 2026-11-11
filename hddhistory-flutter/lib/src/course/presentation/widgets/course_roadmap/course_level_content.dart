part of '../../../course.dart';

class CourseLevelContent extends StatelessWidget {
  final RoadmapLevelEntity roadmapLevel;
  final bool enableSequentialUnlock;
  final Set<String> lockedLessonKeys;
  final CompletedLevelAdditionalContentRequestPromptStatus additionalContentRequestStatus;
  final bool isSubmittingAdditionalContentRequest;
  final Future<bool> Function()? onNoAdditionalContentRequest;
  final VoidCallback? onYesAdditionalContentRequest;
  // The in-progress lesson to auto-scroll to (null when nothing is in progress)
  // and the key to stamp on the "PHẦN" node that holds it. Only the level that
  // actually contains [currentLesson] stamps the key; others are unaffected.
  final LessonEntity? currentLesson;
  final GlobalKey? currentLessonKey;

  /// The course header block belongs to the COURSE, so only the first level
  /// draws it — the design has one header above the whole roadmap, and the
  /// sections below it are the nodes, which title themselves.
  final bool isFirstLevel;

  /// Anchor for the sticky-header title fade; only meaningful on the first
  /// level, which is the one that owns the big title.
  final GlobalKey? courseTitleKey;
  const CourseLevelContent({
    super.key,
    required this.roadmapLevel,
    this.isFirstLevel = false,
    this.courseTitleKey,
    this.enableSequentialUnlock = true,
    this.lockedLessonKeys = const {},
    this.additionalContentRequestStatus = CompletedLevelAdditionalContentRequestPromptStatus.hidden,
    this.isSubmittingAdditionalContentRequest = false,
    this.onNoAdditionalContentRequest,
    this.onYesAdditionalContentRequest,
    this.currentLesson,
    this.currentLessonKey,
  });

  List<bool> get _sequentialUnlockFlags {
    if (!enableSequentialUnlock) return List<bool>.filled(roadmapLevel.nodes.length, false);
    return roadmapLevel.sequentialUnlockFlags;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isFirstLevel) ...[
          CourseRoadmapHeaderCard(titleKey: courseTitleKey),
          26.verticalSpace,
        ],
        ...roadmapLevel.nodes.asMap().entries.map((entry) {
          final node = entry.value;
          // Stamp the auto-scroll anchor on the node that holds the in-progress
          // lesson (a lesson lives in exactly one node, so the GlobalKey stays
          // unique across the whole roadmap).
          final isCurrentNode = currentLesson != null && currentLessonKey != null && node.lessonsList.any((lesson) => lesson.isSameLesson(currentLesson!));
          return RoadmapNodeItem(
            key: isCurrentNode ? currentLessonKey : null,
            node: node,
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
