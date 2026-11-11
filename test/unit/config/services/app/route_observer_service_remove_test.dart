import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('shouldUpdateCurrentRouteOnRemove', () {
    test('true when the removed route was the tracked current one (a real top-of-stack removal)', () {
      expect(
        shouldUpdateCurrentRouteOnRemove(
          removedRouteName: 'Keypoint Complete',
          trackedCurrentRouteName: 'Keypoint Complete',
        ),
        isTrue,
      );
    });

    test('false when the removed route is not the tracked current one (a mid-stack prune)', () {
      // Reproduces: go_router pushes KeypointComplete on top of Lesson (sibling
      // routes, both children of course-roadmap), then prunes the no-longer-
      // reachable Lesson route. didRemove(Lesson, previousRoute=CourseRoadmap)
      // must NOT overwrite currentRouteName — KeypointComplete is still on top.
      expect(
        shouldUpdateCurrentRouteOnRemove(
          removedRouteName: 'Lesson',
          trackedCurrentRouteName: 'Keypoint Complete',
        ),
        isFalse,
      );
    });

    test('false when the removed route name is empty (anonymous overlay route)', () {
      expect(
        shouldUpdateCurrentRouteOnRemove(
          removedRouteName: '',
          trackedCurrentRouteName: 'Keypoint Complete',
        ),
        isFalse,
      );
    });
  });
}
