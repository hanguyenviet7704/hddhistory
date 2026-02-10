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

  group('QuestionLegacyAdapterX.payloadOrLegacy', () {
    test('returns typed payload when typed payload is provided', () {
      const question = QuestionEntity(
        type: QuestionTypeEnum.singleChoice,
        typedPayload: QuestionPayloadEntity.multipleChoice(
          options: [
            QuestionChoiceOptionEntity(
              value: BaseMultiLanguage(en: 'A'),
              isCorrect: true,
            ),
          ],
        ),
        options: [
          OptionEntity(
            value: BaseMultiLanguage(en: 'legacy'),
          ),
        ],
      );

      final payload = question.payloadOrLegacy;
      expect(payload, isA<QuestionMultipleChoicePayloadEntity>());
      expect((payload as QuestionMultipleChoicePayloadEntity).options.first.value.en, 'A');
    });

    test('infers typed payload from legacy fields when typed payload is default', () {
      const question = QuestionEntity(
        type: QuestionTypeEnum.dragAndDrop,
        targetArea: BaseMultiLanguage(en: 'I ___ to school'),
        options: [
          OptionEntity(
            id: 10,
            text: BaseMultiLanguage(en: 'go'),
            value: BaseMultiLanguage(en: 'go'),
          ),
        ],
        answer: [
          AnswerEntity(
            id: 10,
            correctAnswer: BaseMultiLanguage(en: 'go'),
          ),
        ],
      );

      final payload = question.payloadOrLegacy;
      expect(payload, isA<QuestionDragAndDropPayloadEntity>());

      final typed = payload as QuestionDragAndDropPayloadEntity;
      expect(typed.targetArea.en, 'I ___ to school');
      expect(typed.options.single.id, 10);
      expect(typed.answers.single.correctAnswer.en, 'go');
    });

    test('keeps default payload when both typed and legacy payload data are empty', () {
      const question = QuestionEntity();

      final payload = question.payloadOrLegacy;
      expect(payload, const QuestionPayloadEntity.singleChoice());
    });
  });
}
