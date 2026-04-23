import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

LessonEntity _blockingLesson(String id, ProcessEnum progress) {
  return LessonEntity(
    id: id,
    type: LessonType.lesson,
    progess: progress,
    keypoints: [
      KeypointEntity(
        id: '$id-keypoint',
        progess: progress,
      ),
    ],
  );
}

RoadmapLevelEntity _level(
  CourseLevel level,
  ProcessEnum progress,
) {
  return RoadmapLevelEntity(
    level: level,
    nodes: [
      RoadmapNodeEntity(
        lessons: [
          _blockingLesson('${level.name}-lesson', progress),
        ],
      ),
    ],
  );
}

CompletedLevelEntity _completedLevel({
  required CourseLevel level,
  bool? requested,
}) {
  return CompletedLevelEntity(
    level: level,
    completedAt: DateTime(2026),
    additionalContentRequest: requested == null
        ? null
        : CompletedLevelAdditionalContentRequestEntity(
            requested: requested,
            requestText: requested ? 'more speaking' : '',
            submittedAt: DateTime(2026, 1, 2),
          ),
  );
}

void main() {
  group('Roadmap additional content request eligibility', () {
    test('shows default prompt for latest current completed level without request', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
          _level(CourseLevel.level2, ProcessEnum.done),
        ],
      );
      final progress = UserProgressEntity(
        courseId: 'course-1',
        completedLevels: [
          _completedLevel(level: CourseLevel.level2),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.hidden,
      );
      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level2,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.available,
      );
    });

    test('shows selected yes when request exists with requested true', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
        ],
      );
      final progress = UserProgressEntity(
        courseId: 'course-1',
        completedLevels: [
          _completedLevel(level: CourseLevel.level1, requested: true),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.requested,
      );
    });

    test('hides prompt after no request submission', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
        ],
      );
      final progress = UserProgressEntity(
        courseId: 'course-1',
        completedLevels: [
          _completedLevel(level: CourseLevel.level1, requested: false),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.hidden,
      );
    });

    test('hides prompt when backend adds incomplete current roadmap content', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
          _level(CourseLevel.level2, ProcessEnum.notStarted),
        ],
      );
      final progress = UserProgressEntity(
        courseId: 'course-1',
        completedLevels: [
          _completedLevel(level: CourseLevel.level1),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.hidden,
      );
    });

    test('hides prompt when progress belongs to a different course', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
        ],
      );
      final progress = UserProgressEntity(
        courseId: 'course-2',
        completedLevels: [
          _completedLevel(level: CourseLevel.level1),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: progress,
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.hidden,
      );
    });

    test('hides prompt until matching course progress is loaded', () {
      final roadmap = RoadmapEntity(
        courseId: 'course-1',
        levels: [
          _level(CourseLevel.level1, ProcessEnum.done),
        ],
      );

      expect(
        roadmap.additionalContentRequestStateFor(
          level: CourseLevel.level1,
          userProgress: const UserProgressEntity(),
        ),
        CompletedLevelAdditionalContentRequestPromptStatus.hidden,
      );
    });

    test('merges successful empty response into current user progress', () {
      final progress = UserProgressEntity(
        userId: 'user-1',
        courseId: 'course-1',
        completedLevels: [
          _completedLevel(level: CourseLevel.level1),
        ],
      );

      final merged = progress.withCompletedLevelAdditionalContentRequest(
        level: CourseLevel.level1,
        requested: true,
        requestText: 'more dialogs',
        fallbackUserId: 'user-fallback',
        fallbackCourseId: 'course-fallback',
        submittedAt: DateTime(2026, 1, 3),
      );

      final completedLevel = merged.completedLevelFor(CourseLevel.level1);
      expect(completedLevel?.additionalContentRequest?.requested, true);
      expect(completedLevel?.additionalContentRequest?.requestText, 'more dialogs');
      expect(merged.userId, 'user-1');
      expect(merged.courseId, 'course-1');
    });
  });
}
