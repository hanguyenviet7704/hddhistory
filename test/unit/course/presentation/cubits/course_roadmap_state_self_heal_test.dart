import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldEnsureRoadmapReload', () {
    CourseRoadmapState stateWith({
      String courseId = 'course-1',
      List<RoadmapLevelEntity> levels = const [],
      CourseRoadmapStatus status = CourseRoadmapStatus.initial,
    }) {
      return CourseRoadmapState(
        status: status,
        roadmap: RoadmapEntity(courseId: courseId, levels: levels),
      );
    }

    test('true when roadmap is blank for a known course (failed/never-ran load)', () {
      expect(
        shouldEnsureRoadmapReload(stateWith(), hasLoadedThisSession: false),
        isTrue,
      );
      expect(
        shouldEnsureRoadmapReload(stateWith(status: CourseRoadmapStatus.failure), hasLoadedThisSession: false),
        isTrue,
      );
      // Blank must self-heal even if a load already ran this session.
      expect(
        shouldEnsureRoadmapReload(stateWith(status: CourseRoadmapStatus.failure), hasLoadedThisSession: true),
        isTrue,
      );
    });

    test('true when hydrated data exists but nothing was fetched this app session (stale cache)', () {
      final hydrated = stateWith(
        levels: [RoadmapLevelEntity(level: CourseLevel.level1)],
        status: CourseRoadmapStatus.success,
      );
      expect(shouldEnsureRoadmapReload(hydrated, hasLoadedThisSession: false), isTrue);
    });

    test('false when data is present and already fetched this session (no-op on re-entry)', () {
      final fresh = stateWith(
        levels: [RoadmapLevelEntity(level: CourseLevel.level1)],
        status: CourseRoadmapStatus.success,
      );
      expect(shouldEnsureRoadmapReload(fresh, hasLoadedThisSession: true), isFalse);
    });

    test('false while a load is in flight (no duplicate fetch)', () {
      expect(
        shouldEnsureRoadmapReload(stateWith(status: CourseRoadmapStatus.loading), hasLoadedThisSession: false),
        isFalse,
      );
    });

    test('false when no course is known (nothing to load — genuine empty)', () {
      expect(
        shouldEnsureRoadmapReload(stateWith(courseId: ''), hasLoadedThisSession: false),
        isFalse,
      );
    });
  });

  group('normalizeHydratedRoadmapState', () {
    test('resets a persisted loading status to initial (process killed mid-fetch)', () {
      final hydrated = CourseRoadmapState(
        status: CourseRoadmapStatus.loading,
        roadmap: RoadmapEntity(courseId: 'course-1'),
      );
      final normalized = normalizeHydratedRoadmapState(hydrated);
      expect(normalized.status, CourseRoadmapStatus.initial);
      expect(normalized.roadmap.courseId, 'course-1');
      expect(shouldEnsureRoadmapReload(normalized, hasLoadedThisSession: false), isTrue);
    });

    test('leaves non-loading statuses untouched', () {
      final success = CourseRoadmapState(status: CourseRoadmapStatus.success);
      expect(identical(normalizeHydratedRoadmapState(success), success), isTrue);
    });
  });
}
