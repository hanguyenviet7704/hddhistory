import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('Daily warm-up P2 widgets', () {
    testWidgets('progress dots render one dot per usable question without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(const DailyWarmUpProgressDots(count: 8, currentIndex: 2)));

      expect(find.byType(AnimatedContainer), findsNWidgets(8));
      expect(tester.takeException(), isNull);
    });

    testWidgets('bottom CTA is disabled until a valid answer exists', (tester) async {
      var tapped = false;
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpBottomCta(
            label: 'Check',
            enabled: false,
            onPressed: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('question step uses daily warm-up copies for choice P2 question types', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_singleChoiceQuestion()))));
      expect(find.byType(DailyWarmUpChoiceAnswerCard), findsWidgets);

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_multipleChoiceQuestion()))));
      expect(find.byType(DailyWarmUpMultipleChoiceAnswerCard), findsWidgets);

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_dragQuestion()))));
      expect(find.byType(DailyWarmUpSentenceBuilder), findsOneWidget);
      expect(find.byType(BlankSlot), findsWidgets);
      expect(find.byType(AnswerCardsArea), findsOneWidget);

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_arrangeQuestion()))));
      expect(find.byKey(const ValueKey('daily-warm-up-arrange-list')), findsOneWidget);
      expect(find.byType(ArrangeSequenceAnswerCard), findsWidgets);

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_cuesQuestion()))));
      expect(find.byKey(const ValueKey('daily-warm-up-cues-sentence-container')), findsOneWidget);
      expect(find.byType(CuesPlacementWordWithDropZone), findsWidgets);
      expect(find.byType(CuesPlacementAvailableMarks), findsOneWidget);

      await tester.pumpWidget(_harness(_questionStep(_stateFor(_stressQuestion()))));
      expect(find.byKey(const ValueKey('daily-warm-up-stress-sentence-container')), findsOneWidget);
      expect(find.byType(MarkStressWordCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('question CTA is reachable and reflects enabled state', (tester) async {
      var checked = false;
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          _questionStep(
            _stateFor(_singleChoiceQuestion()),
            onCheck: () => checked = true,
          ),
        ),
      );
      await tester.tap(find.text('Check'));
      await tester.pump();
      expect(checked, isFalse);

      await tester.pumpWidget(
        _harness(
          _questionStep(
            _stateFor(_singleChoiceQuestion()).copyWith(selectedAnswerIndex: 0),
            onCheck: () => checked = true,
          ),
        ),
      );
      await tester.tap(find.text('Check'));
      await tester.pump();

      expect(checked, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('result sheet toggles explanation when explanation text exists', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpResultBottomSheet(
            result: _result(isCorrect: false),
            question: _multipleChoiceQuestion(),
            explanationText: 'The best answer keeps the tone natural.',
            onContinue: () {},
          ),
        ),
      );

      expect(tester.widget<LessonResultOverlay>(find.byType(LessonResultOverlay)).showExplanation, isFalse);
      expect(find.text('Explain'), findsOneWidget);
      expect(_verticalCenterDelta(tester, find.text('Incorrect!'), find.byKey(const ValueKey('daily-warm-up-result-explain-action'))), lessThanOrEqualTo(1));

      await tester.tap(find.text('Explain'));
      await tester.pumpAndSettle();

      expect(tester.widget<LessonResultOverlay>(find.byType(LessonResultOverlay)).showExplanation, isTrue);
      expect(find.byKey(const ValueKey('daily-warm-up-result-explanation')), findsOneWidget);
      expect(find.text('The best answer keeps the tone natural.'), findsOneWidget);

      await tester.tap(find.text('Close explain'));
      await tester.pumpAndSettle();

      expect(tester.widget<LessonResultOverlay>(find.byType(LessonResultOverlay)).showExplanation, isFalse);
      expect(find.text('Explain'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('result sheet hides explanation action when explanation text is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpResultBottomSheet(
            result: _result(),
            question: _multipleChoiceQuestion(),
            explanationText: '   ',
            onContinue: () {},
          ),
        ),
      );

      expect(find.text('Explain'), findsNothing);
      expect(find.byKey(const ValueKey('daily-warm-up-result-explanation')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('result sheet uses copied lesson-style explanation card for sequence questions', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpResultBottomSheet(
            result: _orderedResult(),
            question: _arrangeQuestion(),
            explanationText: 'Put the actions in the natural order.',
            onContinue: () {},
          ),
        ),
      );

      await tester.tap(find.text('Explain'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('daily-warm-up-lesson-style-explanation-card')), findsOneWidget);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('second'), findsOneWidget);
      expect(find.text('Put the actions in the natural order.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _harness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}

DailyWarmUpQuestionStep _questionStep(
  DailyWarmUpState state, {
  VoidCallback? onCheck,
}) {
  return DailyWarmUpQuestionStep(
    state: state,
    onClose: () {},
    onCheck: onCheck ?? () {},
    onSelectChoice: (_) {},
    onSetOrderedOptionIds: (_) {},
    onPlaceOption: (_, _) {},
    onRemovePlacedOption: (_) {},
    onToggleWordIndex: (_) {},
  );
}

DailyWarmUpState _stateFor(QuestionEntity question) {
  return DailyWarmUpState(
    status: DailyWarmUpStatus.question,
    usableQuestions: [question],
  );
}

QuestionEntity _singleChoiceQuestion() {
  return QuestionEntity(
    id: 1,
    type: QuestionTypeEnum.singleChoice,
    document: [_document('Pick one')],
    typedPayload: QuestionPayloadEntity.singleChoice(
      options: [_choiceOption('A', isCorrect: true), _choiceOption('B')],
    ),
  );
}

QuestionEntity _multipleChoiceQuestion() {
  return QuestionEntity(
    id: 2,
    type: QuestionTypeEnum.multipleChoice,
    document: [_document('Pick many')],
    typedPayload: QuestionPayloadEntity.multipleChoice(
      options: [_choiceOption('A', isCorrect: true), _choiceOption('B', isCorrect: true)],
    ),
  );
}

QuestionEntity _dragQuestion() {
  return QuestionEntity(
    id: 3,
    type: QuestionTypeEnum.dragAndDrop,
    document: [_document('Fill blanks')],
    typedPayload: QuestionPayloadEntity.dragAndDrop(
      targetArea: _text('First ___ second ___'),
      answers: [
        _dragAnswer(id: 1, text: 'First'),
        _dragAnswer(id: 2, text: 'second'),
      ],
      options: [
        _dragOption(id: 1, text: 'First'),
        _dragOption(id: 2, text: 'second'),
      ],
    ),
  );
}

QuestionEntity _arrangeQuestion() {
  return QuestionEntity(
    id: 4,
    type: QuestionTypeEnum.arrangeTheSequence,
    document: [_document('Arrange')],
    typedPayload: QuestionPayloadEntity.arrangeTheSequence(
      answers: [
        _dragAnswer(id: 1, text: 'First'),
        _dragAnswer(id: 2, text: 'second'),
      ],
      options: [
        _dragOption(id: 1, text: 'First'),
        _dragOption(id: 2, text: 'second'),
      ],
    ),
  );
}

QuestionEntity _cuesQuestion() {
  return QuestionEntity(
    id: 5,
    type: QuestionTypeEnum.cuesPlacement,
    document: [_document('Place cue')],
    typedPayload: QuestionPayloadEntity.cuesPlacement(
      targetArea: _text('Pause here'),
      answers: [_dragAnswer(id: 1, text: '1')],
      options: [_dragOption(id: 1, text: '|')],
    ),
  );
}

QuestionEntity _stressQuestion() {
  return QuestionEntity(
    id: 6,
    type: QuestionTypeEnum.stressPlacement,
    document: [_document('Stress word')],
    typedPayload: QuestionPayloadEntity.stressPlacement(
      targetArea: _text('stress this'),
      answers: [_dragAnswer(id: 1, text: '2')],
      options: [_dragOption(id: 1, text: 'stress')],
    ),
  );
}

ContentDocumentEntity _document(String text) {
  return ContentDocumentEntity(data: DocumentDataEntity(content: _text(text)));
}

QuestionChoiceOptionEntity _choiceOption(String text, {bool isCorrect = false}) {
  return QuestionChoiceOptionEntity(value: _text(text), isCorrect: isCorrect);
}

QuestionDragDropAnswerEntity _dragAnswer({required int id, required String text}) {
  return QuestionDragDropAnswerEntity(id: id, correctAnswer: _text(text));
}

QuestionDragDropOptionEntity _dragOption({required int id, required String text}) {
  return QuestionDragDropOptionEntity(id: id, text: _text(text));
}

BaseMultiLanguage _text(String value) => BaseMultiLanguage(en: value, vi: value, zh: value);

DailyWarmUpAnswerResultEntity _result({bool isCorrect = true}) {
  return DailyWarmUpAnswerResultEntity(
    questionId: 1,
    questionIndex: 0,
    type: isCorrect ? DailyWarmUpAnswerResultType.correct : DailyWarmUpAnswerResultType.incorrect,
    isCorrect: isCorrect,
    selectedIndices: [0],
    correctIndices: [0],
  );
}

DailyWarmUpAnswerResultEntity _orderedResult() {
  return const DailyWarmUpAnswerResultEntity(
    questionId: 4,
    questionIndex: 0,
    type: DailyWarmUpAnswerResultType.incorrect,
    isCorrect: false,
    selectedOptionIds: [2, 1],
    correctOptionIds: [1, 2],
  );
}

double _verticalCenterDelta(WidgetTester tester, Finder first, Finder second) {
  return (tester.getCenter(first).dy - tester.getCenter(second).dy).abs();
}
