import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('progress payload mapping', () {
    test('maps no-correct payload to singleChoiceNoCorrectAnswer type', () {
      const payload = QuestionPayloadEntity.singleChoiceNoCorrectAnswer();
      final mappedType = progressQuestionTypeFromPayload(payload);

      expect(mappedType, QuestionType.singleChoiceNoCorrectAnswer);
    });

    test('maps multiple choice payload to multipleChoice type', () {
      const payload = QuestionPayloadEntity.multipleChoice();
      final mappedType = progressQuestionTypeFromPayload(payload);

      expect(mappedType, QuestionType.multipleChoice);
    });

    test('maps no-correct single answer with boolean isCorrect for backend compatibility', () {
      const option = OptionEntity(
        text: BaseMultiLanguage(en: 'Fallback Text', vi: 'Noi dung'),
      );

      final mapped = progressSingleOptionNoCorrect(option);
      final json = mapped?.toJson() ?? {};

      expect(mapped, isNotNull);
      expect(mapped?.value?.en, 'Fallback Text');
      expect(mapped?.isCorrect, isFalse);
      expect(json['isCorrect'], isFalse);
    });

    test('serializes no-correct exercise progress payload with singleAnswer.isCorrect=false', () {
      const params = UpdateUserProgressExerciseParams(
        userId: '698d51e3e47b0ac1bca906a3',
        courseId: '691c2a53b55570d9bdc0d035',
        lessonId: '69afd9f72905bc89a8a8a824',
        keypointId: '69afd9a32905bc89a8a8a772',
        exercises: [
          UpdateUserProgressExerciseData(
            exerciseId: '69e72bcb314ae64a2b262855',
            type: QuestionType.singleChoiceNoCorrectAnswer,
            passed: true,
            score: 10,
            singleAnswer: UpdateUserProgressExerciseOption(
              value: UpdateUserProgressExerciseOptionValue(
                en: '4 hello my name is kacey oeoqojeqj',
              ),
              isCorrect: false,
            ),
          ),
        ],
      );

      final json = params.toJson();

      expect(json, {
        'userId': '698d51e3e47b0ac1bca906a3',
        'courseId': '691c2a53b55570d9bdc0d035',
        'lessonId': '69afd9f72905bc89a8a8a824',
        'keypointId': '69afd9a32905bc89a8a8a772',
        'exercises': [
          {
            'exerciseId': '69e72bcb314ae64a2b262855',
            'type': 'single_choice_no_correct_answer',
            'passed': true,
            'score': 10.0,
            'singleAnswer': {
              'value': {
                'en': '4 hello my name is kacey oeoqojeqj',
              },
              'isCorrect': false,
            },
          },
        ],
      });
    });
  });
}
