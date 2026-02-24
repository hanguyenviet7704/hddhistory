import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

LessonBodyFactory _createFactory({
  required VoidCallback onContinueUnsupported,
}) {
  return LessonBodyFactory(
    onAnswerChecked: (_) {},
    onContinueUnsupported: onContinueUnsupported,
    reviewBodyBuilder: const LessonReviewBodyBuilder(),
  );
}

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('LessonBodyFactory buildExerciseBody', () {
    test('routes payload variants to expected lesson body widgets', () {
      var continued = false;
      final factory = _createFactory(
        onContinueUnsupported: () {
          continued = true;
        },
      );

      final exerciseCases = <({QuestionPayloadEntity payload, Type widgetType})>[
        (payload: const QuestionPayloadEntity.singleChoice(), widgetType: SingleChoiceLessonBody),
        (payload: const QuestionPayloadEntity.singleChoiceNoCorrectAnswer(), widgetType: SingleChoiceNoCorrectAnswerLessonBody),
        (payload: const QuestionPayloadEntity.multipleChoice(), widgetType: MultipleChoiceLessonBody),
        (payload: const QuestionPayloadEntity.dragAndDrop(), widgetType: DragAndDropLessonBody),
        (payload: const QuestionPayloadEntity.arrangeTheSequence(), widgetType: ArrangeTheSequenceLessonBody),
        (payload: const QuestionPayloadEntity.cuesPlacement(), widgetType: CuesPlacementLessonBody),
        (payload: const QuestionPayloadEntity.stressPlacement(), widgetType: MarkStressWordLessonBody),
        (payload: const QuestionPayloadEntity.speaking(), widgetType: SpeakingLessonBody),
      ];

      for (final testCase in exerciseCases) {
        final widget = factory.buildExerciseBody(
          QuestionEntity(
            id: 1,
            typedPayload: testCase.payload,
          ),
        );
        expect(widget.runtimeType, testCase.widgetType);
      }

      final unsupportedQuestion = const QuestionEntity(
        id: 2,
        typedPayload: QuestionPayloadEntity.unsupported(rawType: 'unknown_type'),
      );
      final unsupportedWidget = factory.buildExerciseBody(unsupportedQuestion);
      expect(unsupportedWidget, isA<UnsupportedLessonBody>());
      final unsupportedBody = unsupportedWidget as UnsupportedLessonBody;
      expect(unsupportedBody.isReadOnly, isFalse);
      unsupportedBody.onContinue?.call();
      expect(continued, isTrue);
    });
  });

  group('LessonBodyFactory buildReviewBody', () {
    test('creates read-only review widgets for key payloads', () {
      final factory = _createFactory(onContinueUnsupported: () {});

      final singleReview = factory.buildReviewBody(
        const QuestionEntity(
          id: 10,
          typedPayload: QuestionPayloadEntity.singleChoice(),
        ),
      );
      expect(singleReview, isA<BlocProvider<ChoiceCubit>>());
      final singleChild = (singleReview as BlocProvider<ChoiceCubit>).child;
      expect(singleChild, isA<SingleChoiceLessonBody>());
      expect((singleChild as SingleChoiceLessonBody).isReadOnly, isTrue);

      final multipleReview = factory.buildReviewBody(
        const QuestionEntity(
          id: 11,
          typedPayload: QuestionPayloadEntity.multipleChoice(),
        ),
      );
      expect(multipleReview, isA<BlocProvider<ChoiceCubit>>());
      final multipleChild = (multipleReview as BlocProvider<ChoiceCubit>).child;
      expect(multipleChild, isA<MultipleChoiceLessonBody>());
      expect((multipleChild as MultipleChoiceLessonBody).isReadOnly, isTrue);

      final noCorrectReview = factory.buildReviewBody(
        const QuestionEntity(
          id: 12,
          typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(),
        ),
      );
      expect(noCorrectReview, isA<BlocProvider<ChoiceCubit>>());
      final noCorrectChild = (noCorrectReview as BlocProvider<ChoiceCubit>).child;
      expect(noCorrectChild, isA<SingleChoiceNoCorrectAnswerLessonBody>());
      expect((noCorrectChild as SingleChoiceNoCorrectAnswerLessonBody).isReadOnly, isTrue);

      final unsupportedReview = factory.buildReviewBody(
        const QuestionEntity(
          id: 13,
          typedPayload: QuestionPayloadEntity.unsupported(rawType: 'legacy_unknown'),
        ),
      );
      expect(unsupportedReview, isA<UnsupportedLessonBody>());
      expect((unsupportedReview as UnsupportedLessonBody).isReadOnly, isTrue);
    });
  });

  group('LessonBodyFactory buildBottomButton', () {
    testWidgets('routes to each lesson body bottom button implementation', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);
      final factory = _createFactory(onContinueUnsupported: () {});

      final capturedButtons = <Widget>[];

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => TranslationProvider(
            child: MaterialApp(
              home: Scaffold(body: child),
            ),
          ),
          child: Builder(
            builder: (context) {
              capturedButtons.add(factory.buildBottomButton(context, SingleChoiceLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, SingleChoiceNoCorrectAnswerLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, MultipleChoiceLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, DragAndDropLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, ArrangeTheSequenceLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, CuesPlacementLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, MarkStressWordLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, SpeakingLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(
                factory.buildBottomButton(
                  context,
                  const UnsupportedLessonBody(
                    question: QuestionEntity(typedPayload: QuestionPayloadEntity.unsupported(rawType: 'x')),
                    onContinue: _noop,
                  ),
                ),
              );
              capturedButtons.add(factory.buildBottomButton(context, TheoryLessonBody(onAnswerChecked: (_) {})));
              capturedButtons.add(factory.buildBottomButton(context, const SizedBox.shrink()));
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(capturedButtons[0], isA<BlocBuilder<ChoiceCubit, ChoiceState>>());
      expect(capturedButtons[1], isA<BlocBuilder<ChoiceCubit, ChoiceState>>());
      expect(capturedButtons[2], isA<BlocBuilder<ChoiceCubit, ChoiceState>>());
      expect(capturedButtons[3], isA<BlocBuilder<DragAndDropCubit, DragAndDropState>>());
      expect(capturedButtons[4], isA<BlocBuilder<ArrangeTheSequenceCubit, ArrangeTheSequenceState>>());
      expect(capturedButtons[5], isA<BlocBuilder<CuesPlacementCubit, CuesPlacementState>>());
      expect(capturedButtons[6], isA<BlocBuilder<MarkStressWordCubit, MarkStressWordState>>());
      expect(capturedButtons[7], isA<SpeakingBottomAction>());
      expect(capturedButtons[8], isA<ExerciseContinueButton>());
      expect(capturedButtons[9], isA<BlocBuilder<TheoryCubit, TheoryState>>());
      expect(capturedButtons[10], isA<SizedBox>());
    });
  });
}

void _noop() {}
