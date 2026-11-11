import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

const _noCorrectQuestion = QuestionEntity(
  id: 101,
  exerciseId: 'exercise-101',
  typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
    options: [
      QuestionNoCorrectChoiceOptionEntity(
        value: BaseMultiLanguage(en: 'Option A', vi: 'Lua chon A'),
      ),
      QuestionNoCorrectChoiceOptionEntity(
        value: BaseMultiLanguage(en: 'Option B', vi: 'Lua chon B'),
      ),
    ],
  ),
);

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('ChoiceCubit no-correct result replay', () {
    test('restores selected answer and keeps answer state correct', () {
      final cubit = ChoiceCubit()..setQuestion(_noCorrectQuestion);

      const persistedResult = ExerciseResultEntity(
        exerciseId: 'exercise-101',
        passed: true,
        singleAnswer: OptionEntity(
          value: BaseMultiLanguage(en: 'Option B', vi: 'Lua chon B'),
        ),
      );

      cubit.applyExerciseResult(persistedResult);

      expect(cubit.state.selectedAnswerIndex, 1);
      expect(cubit.state.hasChecked, isTrue);
      expect(cubit.state.isCorrect, isTrue);
      expect(cubit.state.getAnswerState(1), AnswerState.correct);
      expect(cubit.state.getAnswerState(0), AnswerState.disabled);

      final replayedResult = cubit.toExerciseResult();
      expect(replayedResult.singleAnswer.labelText, 'Option B');
    });

    test('keeps incorrect state when persisted answer cannot be resolved', () {
      final cubit = ChoiceCubit()..setQuestion(_noCorrectQuestion);

      const persistedResult = ExerciseResultEntity(
        exerciseId: 'exercise-101',
        passed: true,
        singleAnswer: OptionEntity(
          value: BaseMultiLanguage(en: 'Not Found'),
        ),
      );

      cubit.applyExerciseResult(persistedResult);

      expect(cubit.state.selectedAnswerIndex, -1);
      expect(cubit.state.hasChecked, isTrue);
      expect(cubit.state.isCorrect, isFalse);
    });
  });
}
