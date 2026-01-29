part of '../../../course.dart';

class RoadmapNodeItem extends StatelessWidget {
  final RoadmapNodeEntity node;
  final CourseLevel courseLevel;
  final int lockedLessonStartIndex;
  final List<LessonEntity> levelLessons;

  const RoadmapNodeItem({
    super.key,
    required this.node,
    required this.courseLevel,
    required this.lockedLessonStartIndex,
    required this.levelLessons,
  });

  @override
  Widget build(BuildContext context) {
    // Data Hydration:
    // 1. Roleplay
    final roleplay = node.roleplay.id.isNotEmpty
        ? node.roleplay
        : levelLessons.firstWhere(
            (l) => l.id == node.roleplayId,
            orElse: () => const LessonEntity(),
          );

    // 2. Output
    final output = node.output.id.isNotEmpty
        ? node.output
        : levelLessons.firstWhere(
            (l) => l.id == node.outputId,
            orElse: () => const LessonEntity(),
          );

    // 3. Lessons (hydrated)
    List<LessonEntity> rawLessons = [];
    if (node.lessonIds.isNotEmpty) {
      rawLessons = node.lessonIds
          .map((id) {
            return levelLessons.firstWhere(
              (l) => l.id == id,
              orElse: () => const LessonEntity(),
            );
          })
          .where((l) => l.id.isNotEmpty)
          .toList();
    } else {
      rawLessons = node.lessons;
    }

    // 4. Flatten Lessons into Keypoints (if applicable)
    // If a lesson has keypoints, we display those keypoints as individual timeline items (LessonEntity wrappers).
    // If no keypoints, we display the lesson itself.
    List<LessonEntity> flattenedKeypoints = [];
    for (var l in rawLessons) {
      if (l.keypoints.isNotEmpty) {
        for (var kp in l.keypoints) {
          flattenedKeypoints.add(
            l.copyWith(
              // Use Parent ID so 'Start Learning' launches the main lesson
              id: l.id,
              // Use Keypoint metadata for display
              title: kp.title,
              description: kp.description,
              estimateCompleTime: kp.estimateCompleTime,
              progess: kp.progess,
              // Keep parent type/icon
              type: LessonType.lesson,
              keypoints: [], // Clear inner keypoints to prevent recursion if any
            ),
          );
        }
      } else {
        flattenedKeypoints.add(l);
      }
    }

    // Combine all valid items
    final items = [
      if (roleplay.id.isNotEmpty) roleplay,
      ...flattenedKeypoints,
      if (output.id.isNotEmpty) output,
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RoadmapSessionHeader(
          title: node.title,
          description: node.description,
        ),

        // Timeline Items
        Column(
          children: List.generate(items.length, (index) {
            final lesson = items[index];
            final isFirst = index == 0;
            final isLast = index == items.length - 1;

            // Determine locked status
            // Use lesson.id (which is Parent ID for keypoints) to find index in levelLessons.
            // Note: Multiple keypoints share same Parent ID, so they will share same Locked status.
            final flatIndex = levelLessons.indexWhere((l) => l.id == lesson.id);
            final isLocked = flatIndex >= 0 && flatIndex >= lockedLessonStartIndex;

            // Determine type for styling
            final isRoleplay = lesson.type == LessonType.roleplay;
            final isKeypoint = lesson.type == LessonType.lesson;

            // Icon Priority: lesson.icon.url -> lesson.lightIcon.url -> Default SVG
            final String? iconUrl = lesson.icon.url.isNotEmpty ? lesson.icon.url : (lesson.lightIcon.url.isNotEmpty ? lesson.lightIcon.url : null);

            final String defaultIconAsset;
            if (isRoleplay) {
              defaultIconAsset = AppAsset.svg.app.icSend;
            } else if (isKeypoint) {
              defaultIconAsset = AppAsset.svg.app.icBook;
            } else {
              defaultIconAsset = AppAsset.svg.app.icAim; // Default/Output
            }

            // Child widget
            Widget content;
            if (isRoleplay) {
              content = RoadmapRoleplayCard(
                lesson: lesson,
                isLocked: isLocked,
                onTap: () {
                  if (isLocked) return;
                  final trackingData = CourseLessonTrackingData.fromLesson(context, lesson);
                  if (trackingData != null) {
                    AppService.instance.appTrackingService.trackRoadmapItemClick(
                      trackingData,
                      itemType: 'roadmap_roleplay_item',
                    );
                  }
                  context.read<CourseLessonCubit>()
                    ..reset()
                    ..loadLesson(lesson.id);
                  LessonListRoute().go(context);
                  context.read<CourseRoadmapCubit>()
                    ..setCurrentCourseLevel(courseLevel)
                    ..setCurrentLesson(lesson);
                },
              );
            } else {
              // Keypoint / Output using LessonCard but with overridden tap for Keypoint
              content = LessonCard(
                courseLevel: courseLevel,
                premiumLesson: isLocked,
                lesson: lesson,
                lessonRolePlay: node.roleplay,
                onOverrideTap: isKeypoint
                    ? () => RoadmapDetailPopup.show(
                        context,
                        lesson: lesson,
                        courseLevel: courseLevel,
                      )
                    : null,
              );
            }

            return Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 20.h),
              child: TimelineTile(
                isFirst: isFirst && index == 0,
                isLast: isLast,
                alignment: TimelineAlign.start,
                indicatorStyle: IndicatorStyle(
                  width: 54.w,
                  height: 54.w,
                  padding: EdgeInsets.zero,
                  indicator: Container(
                    padding: EdgeInsets.all(13.5.w),
                    decoration: BoxDecoration(
                      // Figma shows filled background for active icons
                      color: isLocked ? AppCustomColor.neutral100 : AppCustomColor.brandPrimary50,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: iconUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: iconUrl,
                                width: 28.w,
                                height: 28.w,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => SvgPicture.asset(
                                  defaultIconAsset,
                                  width: 24.w,
                                  height: 24.w,
                                  colorFilter: ColorFilter.mode(
                                    isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                errorWidget: (context, url, error) => SvgPicture.asset(
                                  defaultIconAsset,
                                  width: 24.w,
                                  height: 24.w,
                                  colorFilter: ColorFilter.mode(
                                    isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            )
                          : SvgPicture.asset(
                              defaultIconAsset,
                              width: 28.w,
                              height: 28.w,
                              colorFilter: ColorFilter.mode(
                                isLocked ? AppCustomColor.textQuaternary : AppCustomColor.brandPrimary,
                                BlendMode.srcIn,
                              ),
                            ),
                    ),
                  ),
                ),
                beforeLineStyle: LineStyle(
                  color: AppCustomColor.borderSecondary,
                  thickness: 2.0,
                  dotted: true,
                  dotRadius: 2.0,
                  dotSpacing: 6.0,
                ),
                afterLineStyle: LineStyle(
                  color: AppCustomColor.borderSecondary,
                  thickness: 2.0,
                  dotted: true,
                  dotRadius: 2.0,
                  dotSpacing: 6.0,
                ),
                endChild: Padding(
                  padding: EdgeInsets.only(
                    left: 16.w,
                  ),
                  child: content,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
