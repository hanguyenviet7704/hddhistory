import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

const _noCorrectQuestion = QuestionEntity(
  id: 401,
  exerciseId: 'exercise-401',
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

  int nextQuestionCallCount = 0;

  void setLearningItemType(LearningItemType type) {
    emit(state.copyWith(currentLearningItem: LearningItemEntity(type: type)));
  }

  @override
  void nextQuestion() {
    nextQuestionCallCount += 1;
  }
}

class _TestChoiceCubit extends ChoiceCubit {
  void markCheckedNoCorrect() {
    emit(
      state.copyWith(
        selectedAnswerIndex: 0,
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

  testWidgets('pushes no-correct document route and advances after pop', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    final exerciseCubit = _SpyExerciseCubit()..setLearningItemType(LearningItemType.exercise);
    final choiceCubit = _TestChoiceCubit()..setQuestion(_noCorrectQuestion);

    if (AppDI.injector.isRegistered<ExerciseCubit>()) {
      AppDI.injector.unregister<ExerciseCubit>();
    }
    AppDI.injector.registerSingleton<ExerciseCubit>(exerciseCubit);

    var routedToDocumentPage = false;

    final router = GoRouter(
      initialLocation: '/course-roadmap/lesson',
      routes: [
        GoRoute(
          path: '/course-roadmap/lesson',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<ExerciseCubit>.value(value: exerciseCubit),
                BlocProvider<ChoiceCubit>.value(value: choiceCubit),
              ],
              child: Scaffold(
                body: SingleChoiceNoCorrectAnswerLessonBody(onAnswerChecked: (_) {}),
              ),
            );
          },
        ),
        GoRoute(
          path: '/course-roadmap/no-correct-answer-document/:groupId',
          builder: (context, state) {
            routedToDocumentPage = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pop(true);
            });
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    choiceCubit.markCheckedNoCorrect();

    await tester.pumpAndSettle();

    expect(routedToDocumentPage, isTrue);
    expect(exerciseCubit.nextQuestionCallCount, 1);

    await choiceCubit.close();
    await exerciseCubit.close();
  });

  testWidgets('does not advance when no-correct document route returns false', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.vi);

    final exerciseCubit = _SpyExerciseCubit()..setLearningItemType(LearningItemType.exercise);
    final choiceCubit = _TestChoiceCubit()..setQuestion(_noCorrectQuestion);

    if (AppDI.injector.isRegistered<ExerciseCubit>()) {
      AppDI.injector.unregister<ExerciseCubit>();
    }
    AppDI.injector.registerSingleton<ExerciseCubit>(exerciseCubit);

    final router = GoRouter(
      initialLocation: '/course-roadmap/lesson',
      routes: [
        GoRoute(
          path: '/course-roadmap/lesson',
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<ExerciseCubit>.value(value: exerciseCubit),
                BlocProvider<ChoiceCubit>.value(value: choiceCubit),
              ],
              child: Scaffold(
                body: SingleChoiceNoCorrectAnswerLessonBody(onAnswerChecked: (_) {}),
              ),
            );
          },
        ),
        GoRoute(
          path: '/course-roadmap/no-correct-answer-document/:groupId',
          builder: (context, state) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              context.pop(false);
            });
            return const SizedBox.shrink();
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => TranslationProvider(
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    choiceCubit.markCheckedNoCorrect();

    await tester.pumpAndSettle();

    expect(exerciseCubit.nextQuestionCallCount, 0);

    await choiceCubit.close();
    await exerciseCubit.close();
  });
}
