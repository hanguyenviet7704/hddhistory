import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  test('stores local recording result before submit advances the lesson review list', () async {
    final tempDir = Directory.systemTemp.createTempSync('speaking-cubit-test-');
    addTearDown(() {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    final audioFile = File('${tempDir.path}/answer.m4a')..writeAsBytesSync(const [1, 2, 3]);
    final exerciseItem = _exerciseItem(_speakingQuestion);

    final exerciseCubit = _TestExerciseCubit()..seedLearningItem(exerciseItem);
    final lessonCubit = _TestLessonCubit(exerciseCubit)..seedLearningItem(exerciseItem);
    final speakingCubit = _TestSpeakingCubit()
      ..setQuestion(_speakingQuestion)
      ..finishRecordingSession(audioFile.path);

    addTearDown(exerciseCubit.close);
    addTearDown(lessonCubit.close);
    addTearDown(speakingCubit.close);

    AppDI.injector.registerSingleton<ExerciseCubit>(exerciseCubit);
    AppDI.injector.registerSingleton<LessonCubit>(lessonCubit);

    await speakingCubit.submitAnswer();

    final storedQuestion = lessonCubit.state.pageData.items.single.questions.single;
    expect(storedQuestion.result.recordAnswer.record, audioFile.path);
  });
}

const _speakingQuestion = QuestionEntity(
  id: 902,
  exerciseId: 'exercise-902',
  type: QuestionTypeEnum.speaking,
  typedPayload: QuestionPayloadEntity.speaking(),
);

LearningItemEntity _exerciseItem(QuestionEntity question) {
  return LearningItemEntity(
    id: 'learning-item-902',
    keypointId: 'keypoint-902',
    type: LearningItemType.exercise,
    mainQuestions: [question],
  );
}

class _TestSpeakingCubit extends SpeakingCubit {
  _TestSpeakingCubit()
    : super(
        SendVoiceFeedbackStreamUseCase(_FakeLessonRepository()),
        SendScoreRecordUseCase(_FakeLessonRepository()),
        UploadCubit(UploadFileUseCase(_FakeUploadRepository())),
        AppDI.injector.get<LocaleCubit>(),
      );
}

class _TestLessonCubit extends LessonCubit {
  _TestLessonCubit(ExerciseCubit exerciseCubit)
    : super(
        _FakeGetAllLearningItemsUseCase(),
        _FakeGetLearningItemUseCase(),
        _FakeProgressCubit(),
        exerciseCubit,
        _FakeTheoryCubit(),
      );

  void seedLearningItem(LearningItemEntity item) {
    emit(
      state.copyWith(
        pageData: BasePageBreak<LearningItemEntity>(items: [item]),
        currentLearningItemIndex: 0,
        currentLessonIndex: 0,
      ),
    );
  }
}

class _TestExerciseCubit extends ExerciseCubit {
  _TestExerciseCubit() : super(_FakeGetLearningItemUseCase());

  void seedLearningItem(LearningItemEntity item) {
    emit(state.copyWith(currentLearningItem: item, currentQuestionIndex: 0));
  }
}

class _FakeGetAllLearningItemsUseCase implements GetAllLearningItemsUseCase {
  @override
  TaskEither<AppException, BasePageBreak<LearningItemEntity>> call(PageBreakRequest params) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  TaskEither<AppException, UploadEntity> uploadFile(UploadFileParams params) => TaskEither.left(const AppException.generic('upload skipped'));
}

class _FakeProgressCubit implements ProgressCubit {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTheoryCubit implements TheoryCubit {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
