import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

void main() {
  group('RoadmapNodeActionHelper.resolveOutputPracticeSectionId', () {
    test('returns node id when output lesson id matches node.output.id', () {
      final lesson = LessonEntity(id: 'output-1', type: LessonType.output);
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                id: 'section-1',
                output: lesson,
              ),
            ],
          ),
        ],
      );

      final sectionId = RoadmapNodeActionHelper.resolveOutputPracticeSectionId(roadmap, lesson);

      expect(sectionId, 'section-1');
    });

    test('falls back to node.outputId when output entity is empty', () {
      final lesson = LessonEntity(id: 'output-2', type: LessonType.output);
      final roadmap = RoadmapEntity(
        levels: [
          RoadmapLevelEntity(
            nodes: [
              RoadmapNodeEntity(
                id: 'section-2',
                outputId: 'output-2',
              ),
            ],
          ),
        ],
      );

      final sectionId = RoadmapNodeActionHelper.resolveOutputPracticeSectionId(roadmap, lesson);

      expect(sectionId, 'section-2');
    });
  });
}
