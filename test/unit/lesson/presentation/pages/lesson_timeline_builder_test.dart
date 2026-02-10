import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  const builder = LessonTimelineBuilder();

  group('LessonTimelineBuilder.collectLessonItems', () {
    test('builds completed theory items then active exercise body', () {
      final theoryItem = LearningItemEntity(
        id: 'theory-1',
        type: LearningItemType.theory,
        documents: const [
          DocumentEntity(id: 1),
          DocumentEntity(id: 2),
        ],
      );
      final exerciseItem = LearningItemEntity(
        id: 'exercise-1',
        type: LearningItemType.exercise,
        mainQuestions: const [
          QuestionEntity(id: 11),
          QuestionEntity(id: 12),
        ],
      );

      final state = LessonState(
        pageData: BasePageBreak<LearningItemEntity>(
          items: [theoryItem, exerciseItem],
        ),
        currentLearningItemIndex: 1,
        currentLessonIndex: 0,
      );

      const activeBody = SizedBox(key: Key('active'));
      final reviewQuestions = <int>[];

      final items = builder.collectLessonItems(
        state: state,
        activeBody: activeBody,
        buildReviewBody: (question) {
          reviewQuestions.add(question.id);
          return Text('review-${question.id}');
        },
      );

      expect(items.length, 3);
      expect(items[0], isA<DocumentWidget>());
      expect(items[1], isA<DocumentWidget>());
      expect(identical(items[2], activeBody), isTrue);
      expect(reviewQuestions, isEmpty);
    });

    test('uses review builder for prior exercise questions and active body for current', () {
      final exerciseItem = LearningItemEntity(
        id: 'exercise-2',
        type: LearningItemType.exercise,
        mainQuestions: const [
          QuestionEntity(id: 21),
          QuestionEntity(id: 22),
          QuestionEntity(id: 23),
        ],
      );

      final state = LessonState(
        pageData: BasePageBreak<LearningItemEntity>(
          items: [exerciseItem],
        ),
        currentLearningItemIndex: 0,
        currentLessonIndex: 2,
      );

      const activeBody = SizedBox(key: Key('active-question'));
      final reviewQuestions = <int>[];

      final items = builder.collectLessonItems(
        state: state,
        activeBody: activeBody,
        buildReviewBody: (question) {
          reviewQuestions.add(question.id);
          return Text('review-${question.id}');
        },
      );

      expect(items.length, 3);
      expect(items[0], isA<Text>());
      expect(items[1], isA<Text>());
      expect(identical(items[2], activeBody), isTrue);
      expect(reviewQuestions, [21, 22]);
    });
  });
}
