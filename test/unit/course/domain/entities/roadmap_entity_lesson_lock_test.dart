import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

RoadmapEntity _buildRoadmapWithLessonCount(int lessonCount) {
  final lessons = List.generate(
    lessonCount,
    (index) => LessonEntity(
      id: 'lesson-$index',
      type: LessonType.lesson,
      keypoints: [
        KeypointEntity(id: 'kp-$index'),
      ],
    ),
  );

  return RoadmapEntity(
    id: 'roadmap-1',
    courseId: 'course-1',
    levels: [
      RoadmapLevelEntity(
        id: 1,
        level: CourseLevel.level1,
        nodes: [
          RoadmapNodeEntity(
            id: 'node-1',
            lessons: lessons,
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('RoadmapEntity lesson lock', () {
    test('locks from first lesson when lessonLock is 0', () {
      final roadmap = _buildRoadmapWithLessonCount(10);
      const config = PaywallConfigEntity(
        enableLessonLock: true,
        lessonLock: 0,
      );

      final lockedLessonKeys = roadmap.lockedLessonKeys(config);

      expect(roadmap.lockedLessonStartIndex(config), 0);
      expect(lockedLessonKeys.length, 10);
      expect(lockedLessonKeys.contains('kp-0'), isTrue);
      expect(lockedLessonKeys.contains('kp-9'), isTrue);
    });

    test('locks from lesson index 7 when lessonLock is 7', () {
      final roadmap = _buildRoadmapWithLessonCount(10);
      const config = PaywallConfigEntity(
        enableLessonLock: true,
        lessonLock: 7,
      );

      final lockedLessonKeys = roadmap.lockedLessonKeys(config);

      expect(roadmap.lockedLessonStartIndex(config), 7);
      for (var index = 0; index < 7; index++) {
        expect(lockedLessonKeys.contains('kp-$index'), isFalse);
      }
      for (var index = 7; index < 10; index++) {
        expect(lockedLessonKeys.contains('kp-$index'), isTrue);
      }
    });

    test('does not lock any lesson when lessonLock equals total lessons', () {
      final roadmap = _buildRoadmapWithLessonCount(10);
      const config = PaywallConfigEntity(
        enableLessonLock: true,
        lessonLock: 10,
      );

      expect(roadmap.lockedLessonStartIndex(config), -1);
      expect(roadmap.lockedLessonKeys(config), isEmpty);
    });

    test('does not lock any lesson when lessonLock is negative', () {
      final roadmap = _buildRoadmapWithLessonCount(10);
      const config = PaywallConfigEntity(
        enableLessonLock: true,
        lessonLock: -1,
      );

      expect(roadmap.lockedLessonStartIndex(config), -1);
      expect(roadmap.lockedLessonKeys(config), isEmpty);
      expect(
        roadmap.lockedLessonStartIndexForLevel(
          paywallConfig: config,
          levelIndex: 0,
        ),
        -1,
      );
    });

    test('does not lock any lesson when feature is disabled', () {
      final roadmap = _buildRoadmapWithLessonCount(10);
      const config = PaywallConfigEntity(
        enableLessonLock: false,
        lessonLock: 0,
      );

      expect(roadmap.lockedLessonStartIndex(config), -1);
      expect(roadmap.lockedLessonKeys(config), isEmpty);
    });
  });
}
