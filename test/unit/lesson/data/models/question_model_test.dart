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

  group('QuestionModel.toEntity', () {
    test('maps single_choice_no_correct_answer payload and document groups', () {
      const model = QuestionModel(
        id: 11,
        exerciseId: 'exercise-11',
        type: QuestionType.singleChoiceNoCorrectAnswer,
        options: [
          OptionModel(
            value: BaseMultiLanguage(en: 'Option A', vi: 'Lua chon A'),
            documentGroupId: 'group-1',
          ),
          OptionModel(
            value: BaseMultiLanguage(en: 'Option B', vi: 'Lua chon B'),
            documentGroupId: 'group-2',
          ),
        ],
        documentGroups: [
          NoCorrectDocumentGroupModel(id: 'group-1'),
          NoCorrectDocumentGroupModel(id: 'group-2'),
        ],
      );

      final entity = model.toEntity();
      final payload = entity.typedPayload;

      expect(entity.type, QuestionTypeEnum.singleChoice);
      expect(payload, isA<QuestionSingleChoiceNoCorrectAnswerPayloadEntity>());

      final typedPayload = payload as QuestionSingleChoiceNoCorrectAnswerPayloadEntity;
      expect(typedPayload.options, hasLength(2));
      expect(typedPayload.options.first.value.en, 'Option A');
      expect(typedPayload.options.first.documentGroupId, 'group-1');
      expect(typedPayload.documentGroups.map((group) => group.id), ['group-1', 'group-2']);
    });

    test('maps unknown question type to unsupported payload', () {
      const model = QuestionModel(
        id: 99,
        exerciseId: 'exercise-99',
        type: QuestionType.unknown,
      );

      final entity = model.toEntity();
      final payload = entity.typedPayload;

      expect(payload, isA<QuestionUnsupportedPayloadEntity>());
      expect((payload as QuestionUnsupportedPayloadEntity).rawType, 'unknown');
    });
  });
}
