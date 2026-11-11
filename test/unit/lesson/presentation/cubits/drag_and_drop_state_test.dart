import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('DragAndDropState.isAllFilled', () {
    test('uses visible target blanks instead of extra payload answers', () {
      const question = QuestionEntity(
        typedPayload: QuestionPayloadEntity.dragAndDrop(
          targetArea: BaseMultiLanguage(en: 'A ___ B ___ C ___ D'),
          answers: [
            QuestionDragDropAnswerEntity(correctAnswer: BaseMultiLanguage(en: 'one')),
            QuestionDragDropAnswerEntity(correctAnswer: BaseMultiLanguage(en: 'two')),
            QuestionDragDropAnswerEntity(correctAnswer: BaseMultiLanguage(en: 'three')),
            QuestionDragDropAnswerEntity(correctAnswer: BaseMultiLanguage(en: 'distractor')),
          ],
          options: [
            QuestionDragDropOptionEntity(text: BaseMultiLanguage(en: 'one')),
            QuestionDragDropOptionEntity(text: BaseMultiLanguage(en: 'two')),
            QuestionDragDropOptionEntity(text: BaseMultiLanguage(en: 'three')),
            QuestionDragDropOptionEntity(text: BaseMultiLanguage(en: 'distractor')),
          ],
        ),
      );

      const state = DragAndDropState(
        question: question,
        placedWords: {
          0: 'one',
          1: 'two',
          2: 'three',
        },
      );

      expect(state.dropZoneCount, 3);
      expect(state.isAllFilled, isTrue);
    });
  });
}
