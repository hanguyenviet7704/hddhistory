import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  group('resolveNoCorrectAnswerDocumentGroup', () {
    const question = QuestionEntity(
      id: 301,
      typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
        options: [
          QuestionNoCorrectChoiceOptionEntity(
            value: BaseMultiLanguage(en: 'Option A'),
            documentGroupId: 'group-a',
          ),
          QuestionNoCorrectChoiceOptionEntity(
            value: BaseMultiLanguage(en: 'Option B'),
            documentGroupId: 'group-b',
          ),
        ],
        documentGroups: [
          QuestionNoCorrectDocumentGroupEntity(
            id: 'group-a',
            documents: [
              ContentDocumentEntity(
                type: ContentDocumentType.text,
                data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Group A content')),
              ),
            ],
          ),
          QuestionNoCorrectDocumentGroupEntity(
            id: 'group-b',
            documents: [
              ContentDocumentEntity(
                type: ContentDocumentType.text,
                data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Group B content')),
              ),
            ],
          ),
        ],
      ),
    );

    test('resolves matched group from selected index', () {
      final resolved = resolveNoCorrectAnswerDocumentGroup(
        question: question,
        selectedAnswerIndex: 1,
      );

      expect(resolved, isNotNull);
      expect(resolved?.groupId, 'group-b');
      expect(resolved?.documents.single.data.content.en, 'Group B content');
    });

    test('returns null for non no-correct payload', () {
      const singleChoiceQuestion = QuestionEntity(
        typedPayload: QuestionPayloadEntity.singleChoice(
          options: [
            QuestionChoiceOptionEntity(
              value: BaseMultiLanguage(en: 'A'),
              isCorrect: true,
            ),
          ],
        ),
      );

      final resolved = resolveNoCorrectAnswerDocumentGroup(
        question: singleChoiceQuestion,
        selectedAnswerIndex: 0,
      );

      expect(resolved, isNull);
    });

    test('returns null for invalid selected index', () {
      final resolved = resolveNoCorrectAnswerDocumentGroup(
        question: question,
        selectedAnswerIndex: -1,
      );

      expect(resolved, isNull);
    });

    test('returns null when option group cannot be found', () {
      const unmatchedQuestion = QuestionEntity(
        typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
          options: [
            QuestionNoCorrectChoiceOptionEntity(
              value: BaseMultiLanguage(en: 'Option A'),
              documentGroupId: 'missing',
            ),
          ],
          documentGroups: [
            QuestionNoCorrectDocumentGroupEntity(id: 'group-a'),
          ],
        ),
      );

      final resolved = resolveNoCorrectAnswerDocumentGroup(
        question: unmatchedQuestion,
        selectedAnswerIndex: 0,
      );

      expect(resolved, isNull);
    });
  });

  group('resolveNoCorrectAnswerDocumentGroupById', () {
    const question = QuestionEntity(
      typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
        options: [
          QuestionNoCorrectChoiceOptionEntity(
            value: BaseMultiLanguage(en: 'Option A'),
            documentGroupId: 'group-a',
          ),
        ],
        documentGroups: [
          QuestionNoCorrectDocumentGroupEntity(
            id: 'group-a',
            documents: [
              ContentDocumentEntity(
                type: ContentDocumentType.text,
                data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Group A content')),
              ),
            ],
          ),
        ],
      ),
    );

    test('resolves group by id', () {
      final resolved = resolveNoCorrectAnswerDocumentGroupById(
        question: question,
        groupId: 'group-a',
      );

      expect(resolved, isNotNull);
      expect(resolved?.groupId, 'group-a');
      expect(resolved?.documents.single.data.content.en, 'Group A content');
    });

    test('returns null for empty group id', () {
      final resolved = resolveNoCorrectAnswerDocumentGroupById(
        question: question,
        groupId: '',
      );

      expect(resolved, isNull);
    });
  });
}
