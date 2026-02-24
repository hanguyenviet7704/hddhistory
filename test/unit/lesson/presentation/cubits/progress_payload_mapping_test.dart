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

    test('maps no-correct single answer without isCorrect semantics', () {
      const option = OptionEntity(
        text: BaseMultiLanguage(en: 'Fallback Text', vi: 'Noi dung'),
      );

      final mapped = progressSingleOptionNoCorrect(option);
      final json = mapped?.toJson() ?? {};

      expect(mapped, isNotNull);
      expect(mapped?.value?.en, 'Fallback Text');
      expect(mapped?.isCorrect, isNull);
      expect(json.containsKey('isCorrect'), isFalse);
    });
  });
}
