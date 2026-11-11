import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../../support/test_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('renders recorded speaking review for lesson exercises immediately', (tester) async {
    final exerciseCubit = _TestExerciseCubit()..setLearningItemType(LearningItemType.exercise);
    final speakingCubit = _TestSpeakingCubit()
      ..setReviewResult(
        _speakingQuestion,
        const ExerciseResultEntity(
          recordAnswer: AnswerEntity(record: '/tmp/user-recording.m4a'),
        ),
      );

    addTearDown(exerciseCubit.close);
    addTearDown(speakingCubit.close);

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
                BlocProvider<SpeakingCubit>.value(value: speakingCubit),
              ],
              child: const Scaffold(
                body: SpeakingLessonBody(
                  onAnswerChecked: _noopAnswerChecked,
                  isReadOnly: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(AudioPlayerFileWidget), findsOneWidget);
    expect(find.byType(LessonExplainButton), findsOneWidget);
  });
}

const _speakingQuestion = QuestionEntity(
  id: 901,
  exerciseId: 'exercise-901',
  explanation: BaseMultiLanguage(en: 'Review your voice response.'),
  typedPayload: QuestionPayloadEntity.speaking(),
  document: [
    ContentDocumentEntity(
      type: ContentDocumentType.text,
      data: DocumentDataEntity(content: BaseMultiLanguage(en: 'Record your voice response.')),
    ),
  ],
);

void _noopAnswerChecked(bool _) {}

class _TestSpeakingCubit extends SpeakingCubit {
  _TestSpeakingCubit()
    : super(
        SendVoiceFeedbackStreamUseCase(_FakeLessonRepository()),
        SendScoreRecordUseCase(_FakeLessonRepository()),
        UploadCubit(UploadFileUseCase(_FakeUploadRepository())),
        AppDI.injector.get<LocaleCubit>(),
      );
}

class _TestExerciseCubit extends ExerciseCubit {
  _TestExerciseCubit() : super(_FakeGetLearningItemUseCase());

  void setLearningItemType(LearningItemType type) {
    emit(state.copyWith(currentLearningItem: LearningItemEntity(type: type)));
  }
}

class _FakeGetLearningItemUseCase implements GetLearningItemUseCase {
  @override
  TaskEither<AppException, LearningItemEntity> call(String params) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLessonRepository implements ILessonRepository {
  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> getAllLearningItems(PageBreakRequest request) => throw UnimplementedError();

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) => throw UnimplementedError();

  @override
  TaskEither<AppException, VoiceFeedbackEntity> sendVoiceFeedback(VoiceFeedbackRequest request) => throw UnimplementedError();

  @override
  TaskEither<AppException, ResponseBody> sendVoiceFeedbackStream(VoiceFeedbackRequest request) => throw UnimplementedError();

  @override
  TaskEither<AppException, VoiceScoreEntity> sendScoreRecord(Map<String, dynamic> params) => throw UnimplementedError();
}

class _FakeUploadRepository implements IUploadRepository {
  @override
  TaskEither<AppException, UploadEntity> uploadFile(UploadFileParams params) => throw UnimplementedError();
}
