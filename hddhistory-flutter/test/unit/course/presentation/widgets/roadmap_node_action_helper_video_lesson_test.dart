import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('RoadmapNodeActionHelper.resolveVideoLessonNodeId', () {
    test('returns node id when the lesson matches the opening video entity', () {
      final lesson = LessonEntity(id: 'video-1', type: LessonType.video);
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                id: 'node-1',
                openingVideo: lesson,
              ),
            ],
          ),
        ],
      );

      final nodeId = RoadmapNodeActionHelper.resolveVideoLessonNodeId(roadmap, lesson);

      expect(nodeId, 'node-1');
    });

    test('returns node id when the lesson matches the closing video id', () {
      final lesson = LessonEntity(id: 'video-2', type: LessonType.video);
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                id: 'node-2',
                closingVideoId: 'video-2',
              ),
            ],
          ),
        ],
      );

      final nodeId = RoadmapNodeActionHelper.resolveVideoLessonNodeId(roadmap, lesson);

      expect(nodeId, 'node-2');
    });

    test('returns empty when the same lesson resolves to multiple nodes', () {
      final lesson = LessonEntity(id: 'video-3', type: LessonType.video);
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                id: 'node-3',
                openingVideoId: 'video-3',
              ),
              RoadmapNodeEntity(
                id: 'node-4',
                closingVideoId: 'video-3',
              ),
            ],
          ),
        ],
      );

      final nodeId = RoadmapNodeActionHelper.resolveVideoLessonNodeId(roadmap, lesson);

      expect(nodeId, isEmpty);
    });
  });

  group('RoadmapNodeActionHelper.resolveVideoLessonCourseId', () {
    test('uses the lesson course id when it is present', () {
      final lesson = LessonEntity(
        id: 'video-4',
        type: LessonType.video,
        courseId: 'course-from-lesson',
      );
      final roadmap = const RoadmapEntity(courseId: 'course-from-roadmap');

      final courseId = RoadmapNodeActionHelper.resolveVideoLessonCourseId(roadmap, lesson);

      expect(courseId, 'course-from-lesson');
    });

    test('falls back to roadmap course id when lesson course id is empty', () {
      final lesson = LessonEntity(
        id: 'video-5',
        type: LessonType.video,
      );
      final roadmap = const RoadmapEntity(courseId: 'course-from-roadmap');

      final courseId = RoadmapNodeActionHelper.resolveVideoLessonCourseId(roadmap, lesson);

      expect(courseId, 'course-from-roadmap');
    });
  });
}
