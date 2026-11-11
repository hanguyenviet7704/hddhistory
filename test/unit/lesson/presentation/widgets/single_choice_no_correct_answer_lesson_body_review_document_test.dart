import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

const _questionWithMatchedGroup = QuestionEntity(
  id: 701,
  exerciseId: 'exercise-701',
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
            data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Inline group content')),
          ),
        ],
      ),
    ],
  ),
);

const _questionWithUnmatchedGroup = QuestionEntity(
  id: 702,
  exerciseId: 'exercise-702',
  typedPayload: QuestionPayloadEntity.singleChoiceNoCorrectAnswer(
    options: [
      QuestionNoCorrectChoiceOptionEntity(
        value: BaseMultiLanguage(en: 'Option B'),
        documentGroupId: 'group-missing',
      ),
    ],
    documentGroups: [
      QuestionNoCorrectDocumentGroupEntity(
        id: 'group-a',
        documents: [
          ContentDocumentEntity(
            type: ContentDocumentType.text,
            data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Should not show')),
          ),
        ],
      ),
    ],
  ),
);

class _StubLessonRepository implements ILessonRepository {
  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(PageBreakRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, VoiceFeedbackEntity> sendVoiceFeedback(VoiceFeedbackRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, ResponseBody> sendVoiceFeedbackStream(VoiceFeedbackRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, VoiceScoreEntity> sendScoreRecord(Map<String, dynamic> params) {
    throw UnimplementedError();
  }
}

class _SpyExerciseCubit extends ExerciseCubit {
  _SpyExerciseCubit()
    : super(
        GetLearningItemUseCase(_StubLessonRepository()),
      );

  void setLearningItemType(LearningItemType type) {
    emit(state.copyWith(currentLearningItem: LearningItemEntity(type: type)));
  }
}

class _TestChoiceCubit extends ChoiceCubit {
  void setReviewedQuestion({
    required QuestionEntity question,
    required int selectedAnswerIndex,
  }) {
    emit(
      state.copyWith(
        question: question,
        selectedAnswerIndex: selectedAnswerIndex,
        hasChecked: true,
        isCorrect: true,
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setupLocaleCubitForTests();
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  testWidgets('shows matched inline document for reviewed no-correct exercise item', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    final exerciseCubit = _SpyExerciseCubit()..setLearningItemType(LearningItemType.exercise);
    final choiceCubit = _TestChoiceCubit()
      ..setReviewedQuestion(
        question: _questionWithMatchedGroup,
        selectedAnswerIndex: 0,
      );

    if (AppDI.injector.isRegistered<ExerciseCubit>()) {
      AppDI.injector.unregister<ExerciseCubit>();
    }
    AppDI.injector.registerSingleton<ExerciseCubit>(exerciseCubit);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ExerciseCubit>.value(value: exerciseCubit),
                BlocProvider<ChoiceCubit>.value(value: choiceCubit),
              ],
              child: Scaffold(
                body: SingleChoiceNoCorrectAnswerLessonBody(
                  onAnswerChecked: _noopAnswerChecked,
                  isReadOnly: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Inline group content'), findsOneWidget);

    await choiceCubit.close();
    await exerciseCubit.close();
  });

  testWidgets('does not show inline document when selected answer cannot resolve document group', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    final exerciseCubit = _SpyExerciseCubit()..setLearningItemType(LearningItemType.exercise);
    final choiceCubit = _TestChoiceCubit()
      ..setReviewedQuestion(
        question: _questionWithUnmatchedGroup,
        selectedAnswerIndex: 0,
      );

    if (AppDI.injector.isRegistered<ExerciseCubit>()) {
      AppDI.injector.unregister<ExerciseCubit>();
    }
    AppDI.injector.registerSingleton<ExerciseCubit>(exerciseCubit);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider<ExerciseCubit>.value(value: exerciseCubit),
                BlocProvider<ChoiceCubit>.value(value: choiceCubit),
              ],
              child: Scaffold(
                body: SingleChoiceNoCorrectAnswerLessonBody(
                  onAnswerChecked: _noopAnswerChecked,
                  isReadOnly: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Should not show'), findsNothing);

    await choiceCubit.close();
    await exerciseCubit.close();
  });
}

void _noopAnswerChecked(bool _) {}
