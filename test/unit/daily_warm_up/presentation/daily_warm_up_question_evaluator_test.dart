import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('daily warm-up question evaluator', () {
    test('Given multiple choice with an extra wrong selection, When evaluated, Then result is incorrect', () {
      final question = _choiceQuestion(
        type: QuestionTypeEnum.multipleChoice,
        options: [
          _choiceOption('A', isCorrect: true),
          _choiceOption('B', isCorrect: true),
          _choiceOption('C'),
        ],
      );

      final result = evaluateDailyWarmUpQuestion(
        question,
        selectedAnswersIndices: {0, 1, 2},
      );

      expect(result.isCorrect, isFalse);
      expect(result.type, DailyWarmUpAnswerResultType.incorrect);
    });

    test('Given no-correct single choice, When selected, Then result is neutral completed', () {
      final question = _choiceQuestion(
        type: QuestionTypeEnum.singleChoice,
        payload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
          options: [_noCorrectOption('A')],
        ),
      );

      final result = evaluateDailyWarmUpQuestion(question, selectedAnswerIndex: 0);

      expect(result.isCorrect, isTrue);
      expect(result.type, DailyWarmUpAnswerResultType.neutral);
    });

    test('Given speaking and malformed questions, When filtered, Then only usable non-speaking remains', () {
      final usable = _choiceQuestion(
        id: 1,
        options: [_choiceOption('A', isCorrect: true), _choiceOption('B')],
      );
      final speaking = _choiceQuestion(
        id: 2,
        type: QuestionTypeEnum.speaking,
        payload: const QuestionPayloadEntity.speaking(record: 'hello'),
      );
      final malformed = _choiceQuestion(id: 3, options: const []);

      final filtered = filterUsableDailyWarmUpQuestions([speaking, malformed, usable]);

      expect(filtered.map((question) => question.id), [1]);
    });

    test('Given drag answer ids, When option labels duplicate, Then evaluation uses stable ids', () {
      final question = _dragQuestion(
        answers: [
          _dragAnswer(id: 2, text: 'Same'),
          _dragAnswer(id: 1, text: 'Same'),
        ],
        options: [
          _dragOption(id: 1, text: 'Same'),
          _dragOption(id: 2, text: 'Same'),
        ],
      );

      final result = evaluateDailyWarmUpQuestion(
        question,
        placedOptionIds: {0: 2, 1: 1},
      );

      expect(isUsableDailyWarmUpQuestion(question), isTrue);
      expect(result.isCorrect, isTrue);
    });

    test('Given arrange answer without ids and duplicate labels, When filtered, Then question is skipped', () {
      final question = _arrangeQuestion(
        answers: [
          _dragAnswer(text: 'Same'),
          _dragAnswer(text: 'Other'),
        ],
        options: [
          _dragOption(id: 1, text: 'Same'),
          _dragOption(id: 2, text: 'Same'),
          _dragOption(id: 3, text: 'Other'),
        ],
      );

      expect(isUsableDailyWarmUpQuestion(question), isFalse);
    });

    test('Given cues position outside target text, When filtered, Then question is skipped', () {
      final question = QuestionEntity(
        id: 22,
        type: QuestionTypeEnum.cuesPlacement,
        document: [_document('Place pause')],
        typedPayload: QuestionPayloadEntity.cuesPlacement(
          targetArea: _text('one two'),
          answers: [_dragAnswer(text: '3')],
          options: [_dragOption(id: 1, text: '|')],
        ),
      );

      expect(isUsableDailyWarmUpQuestion(question), isFalse);
    });
  });
}

QuestionEntity _choiceQuestion({
  int id = 10,
  QuestionTypeEnum type = QuestionTypeEnum.singleChoice,
  QuestionPayloadEntity? payload,
  List<QuestionChoiceOptionEntity> options = const [],
}) {
  return QuestionEntity(
    id: id,
    type: type,
    document: [_document('Pick one')],
    typedPayload: payload ?? QuestionPayloadEntity.singleChoice(options: options),
  );
}

ContentDocumentEntity _document(String text) {
  return ContentDocumentEntity(
    data: DocumentDataEntity(content: _text(text)),
  );
}

QuestionChoiceOptionEntity _choiceOption(String text, {bool isCorrect = false}) {
  return QuestionChoiceOptionEntity(value: _text(text), isCorrect: isCorrect);
}

QuestionNoCorrectChoiceOptionEntity _noCorrectOption(String text) {
  return QuestionNoCorrectChoiceOptionEntity(value: _text(text));
}

QuestionEntity _dragQuestion({
  List<QuestionDragDropAnswerEntity> answers = const [],
  List<QuestionDragDropOptionEntity> options = const [],
}) {
  return QuestionEntity(
    id: 20,
    type: QuestionTypeEnum.dragAndDrop,
    document: [_document('Fill blanks')],
    typedPayload: QuestionPayloadEntity.dragAndDrop(
      targetArea: _text('First second'),
      answers: answers,
      options: options,
    ),
  );
}

QuestionEntity _arrangeQuestion({
  List<QuestionDragDropAnswerEntity> answers = const [],
  List<QuestionDragDropOptionEntity> options = const [],
}) {
  return QuestionEntity(
    id: 21,
    type: QuestionTypeEnum.arrangeTheSequence,
    document: [_document('Arrange')],
    typedPayload: QuestionPayloadEntity.arrangeTheSequence(
      answers: answers,
      options: options,
    ),
  );
}

QuestionDragDropAnswerEntity _dragAnswer({int id = 0, required String text}) {
  return QuestionDragDropAnswerEntity(id: id, correctAnswer: _text(text));
}

QuestionDragDropOptionEntity _dragOption({required int id, required String text}) {
  return QuestionDragDropOptionEntity(id: id, text: _text(text));
}

BaseMultiLanguage _text(String value) => BaseMultiLanguage(en: value, vi: value, zh: value);
