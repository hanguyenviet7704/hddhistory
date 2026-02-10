import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('QuestionEntity.fromJson', () {
    test('keeps typed payload when typedPayload exists in json', () {
      const original = QuestionEntity(
        id: 1,
        typedPayload: QuestionPayloadEntity.multipleChoice(
          options: [
            QuestionChoiceOptionEntity(
              value: BaseMultiLanguage(en: 'A'),
              isCorrect: true,
            ),
          ],
        ),
      );

      final parsed = QuestionEntity.fromJson(original.toJson());

      expect(parsed.typedPayload, isA<QuestionMultipleChoicePayloadEntity>());
      final payload = parsed.typedPayload as QuestionMultipleChoicePayloadEntity;
      expect(payload.options, hasLength(1));
      expect(payload.options.first.value.en, 'A');
      expect(payload.options.first.isCorrect, isTrue);
    });

    test('infers drag-and-drop payload from legacy json when typedPayload is missing', () {
      final legacyJson = <String, dynamic>{
        'type': 'drag_and_drop',
        'form': 'Text Gap Filling',
        'targetArea': {
          'en': 'I ___ to school',
          'vi': '',
          'zh': '',
        },
        'options': [
          {
            'id': 10,
            'text': {'en': 'go', 'vi': '', 'zh': ''},
            'value': {'en': 'go', 'vi': '', 'zh': ''},
          },
        ],
        'answer': [
          {
            'id': 10,
            'correctAnswer': {'en': 'go', 'vi': '', 'zh': ''},
          },
        ],
      };

      final parsed = QuestionEntity.fromJson(legacyJson);

      expect(parsed.typedPayload, isA<QuestionDragAndDropPayloadEntity>());
      final payload = parsed.typedPayload as QuestionDragAndDropPayloadEntity;
      expect(payload.targetArea.en, 'I ___ to school');
      expect(payload.options.single.id, 10);
      expect(payload.answers.single.correctAnswer.en, 'go');
    });

    test('infers no-correct single-choice payload from legacy document group data', () {
      final legacyJson = <String, dynamic>{
        'type': 'single_choice',
        'options': [
          {
            'value': {'en': 'Option A', 'vi': '', 'zh': ''},
            'documentGroupId': 'group-1',
          },
        ],
        'documentGroups': [
          {'id': 'group-1'},
        ],
      };

      final parsed = QuestionEntity.fromJson(legacyJson);

      expect(parsed.typedPayload, isA<QuestionSingleChoiceNoCorrectAnswerPayloadEntity>());
      final payload = parsed.typedPayload as QuestionSingleChoiceNoCorrectAnswerPayloadEntity;
      expect(payload.options.single.documentGroupId, 'group-1');
      expect(payload.documentGroups.single.id, 'group-1');
    });
  });
}
