import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

LessonEntity _lesson(
  String id, {
  required LessonType type,
  required ProcessEnum progress,
}) {
  return LessonEntity(
    id: id,
    type: type,
    progess: progress,
    keypoints: type == LessonType.lesson
        ? [
            KeypointEntity(
              id: '$id-keypoint',
              progess: progress,
            ),
          ]
        : const [],
  );
}

void main() {
  group('Roadmap non-blocking progress projection', () {
    test('does not auto-pass non-blocking item before previous blocking lesson is reached', () {
      final items = [
        _lesson('lesson-1', type: LessonType.lesson, progress: ProcessEnum.done),
        _lesson('lesson-2', type: LessonType.lesson, progress: ProcessEnum.notStarted),
        _lesson('output-1', type: LessonType.output, progress: ProcessEnum.notStarted),
        _lesson('lesson-3', type: LessonType.lesson, progress: ProcessEnum.notStarted),
      ];

      final resolved = items.applySequentialUnlock();

      expect(resolved[0].roadmapProgress, ProcessEnum.done);
      expect(resolved[1].roadmapProgress, ProcessEnum.inProgress);
      expect(resolved[2].roadmapProgress, ProcessEnum.notStarted);
      expect(resolved[3].roadmapProgress, ProcessEnum.notStarted);
    });

    test('auto-passes trailing non-blocking item for level progress and completion', () {
      final level = RoadmapLevelEntity(
        nodes: [
          RoadmapNodeEntity(
            lessons: [
              _lesson('lesson-1', type: LessonType.lesson, progress: ProcessEnum.done),
              _lesson('lesson-2', type: LessonType.lesson, progress: ProcessEnum.done),
            ],
            output: _lesson('output-1', type: LessonType.output, progress: ProcessEnum.notStarted),
          ),
        ],
      );

      final resolved = level.resolvedRoadmapLessons();

      expect(resolved.map((lesson) => lesson.roadmapProgress).toList(), [
        ProcessEnum.done,
        ProcessEnum.done,
        ProcessEnum.done,
      ]);
      expect(level.completedLessons, 3);
      expect(level.totalLessons, 3);
      expect(level.progress, 1);
      expect(level.isRoadmapCompleted, true);
    });

    test('opens next level when previous level ends with non-blocking item', () {
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                lessons: [
                  _lesson('lesson-1', type: LessonType.lesson, progress: ProcessEnum.done),
                ],
                output: _lesson('output-1', type: LessonType.output, progress: ProcessEnum.notStarted),
              ),
            ],
          ),
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                lessons: [
                  _lesson('lesson-2', type: LessonType.lesson, progress: ProcessEnum.notStarted),
                ],
              ),
            ],
          ),
        ],
      );

      expect(roadmap.levelSequentialUnlockFlags, [true, true]);
      expect(
        roadmap.displayLessons.map((lesson) => lesson.roadmapProgress).toList(),
        [
          ProcessEnum.done,
          ProcessEnum.done,
          ProcessEnum.inProgress,
        ],
      );
    });
  });
}
