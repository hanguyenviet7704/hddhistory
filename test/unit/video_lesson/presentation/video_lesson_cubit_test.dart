import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

class _TestUserCubit extends UserCubit {
  _TestUserCubit() : super(NoOpTrackingService());

  void setTestUser(UserEntity user) {
    emit(state.copyWith(auth: state.auth.copyWith(user: user)));
  }
}

class _FakeCourseLessonRepository implements ICourseLessonRepository {
  _FakeCourseLessonRepository(this.getCourseLessonHandler);

  TaskEither<AppException, LessonEntity> Function(String lessonId) getCourseLessonHandler;

  @override
  TaskEither<AppException, LessonEntity> getCourseLesson(String id) => getCourseLessonHandler(id);

  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(PageBreakRequest request) {
    throw UnimplementedError();
  }
}

class _FakeVideoLessonRepository implements IVideoLessonRepository {
  _FakeVideoLessonRepository({
    required this.getLearningItemHandler,
    TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> Function(PageBreakRequest<VideoLessonNoteFilterEntity> request)? getAllNotesHandler,
    TaskEither<AppException, UserVideoLessonNoteEntity> Function(UserVideoLessonNoteEntity entity)? createNoteHandler,
    TaskEither<AppException, UserVideoLessonNoteEntity> Function(UserVideoLessonNoteEntity entity)? updateNoteHandler,
    TaskEither<AppException, Unit> Function(UserVideoLessonNoteEntity entity)? deleteNoteHandler,
  }) : getAllNotesHandler = getAllNotesHandler ?? _defaultNotesHandler,
       createNoteHandler = createNoteHandler ?? _defaultCreateNoteHandler,
       updateNoteHandler = updateNoteHandler ?? _defaultUpdateNoteHandler,
       deleteNoteHandler = deleteNoteHandler ?? _defaultDeleteNoteHandler;

  final TaskEither<AppException, LearningItemEntity> Function(String learningItemId) getLearningItemHandler;
  final TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> Function(PageBreakRequest<VideoLessonNoteFilterEntity> request) getAllNotesHandler;
  final TaskEither<AppException, UserVideoLessonNoteEntity> Function(UserVideoLessonNoteEntity entity) createNoteHandler;
  final TaskEither<AppException, UserVideoLessonNoteEntity> Function(UserVideoLessonNoteEntity entity) updateNoteHandler;
  final TaskEither<AppException, Unit> Function(UserVideoLessonNoteEntity entity) deleteNoteHandler;

  static TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> _defaultNotesHandler(
    PageBreakRequest<VideoLessonNoteFilterEntity> request,
  ) => TaskEither.right(
    BasePageBreak<UserVideoLessonNoteEntity>(
      currentPage: request.page,
      totalPages: 1,
      itemsPerPage: 10,
      items: const [],
    ),
  );

  static TaskEither<AppException, UserVideoLessonNoteEntity> _defaultCreateNoteHandler(UserVideoLessonNoteEntity entity) =>
      TaskEither.right(entity.copyWith(id: entity.id.isEmpty ? 'created-note' : entity.id));

  static TaskEither<AppException, UserVideoLessonNoteEntity> _defaultUpdateNoteHandler(UserVideoLessonNoteEntity entity) => TaskEither.right(entity);

  static TaskEither<AppException, Unit> _defaultDeleteNoteHandler(UserVideoLessonNoteEntity entity) => TaskEither.right(unit);

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) => getLearningItemHandler(id);

  @override
  TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> getAllUserVideoLessonNotes(
    PageBreakRequest<VideoLessonNoteFilterEntity> request,
  ) => getAllNotesHandler(request);

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> createUserVideoLessonNote(UserVideoLessonNoteEntity entity) => createNoteHandler(entity);

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> updateUserVideoLessonNote(UserVideoLessonNoteEntity entity) => updateNoteHandler(entity);

  @override
  TaskEither<AppException, Unit> deleteUserVideoLessonNote(UserVideoLessonNoteEntity entity) => deleteNoteHandler(entity);
}

class _FakeCourseRepository implements ICourseRepository {
  int roadmapLoadCount = 0;
  String? lastRoadmapCourseId;

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) {
    roadmapLoadCount += 1;
    lastRoadmapCourseId = id;
    return TaskEither.right(RoadmapEntity(courseId: id));
  }
}

class _FakeProgressRepository implements IProgressRepository {
  UpdateUserProgressLessonParams? lastParams;

  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId, Map<String, dynamic> body) {
    lastParams = UpdateUserProgressLessonParams(lessonId: lessonId, body: body);
    return TaskEither.right(const UserProgressEntity());
  }

  @override
  TaskEither<AppException, UserProgressEntity> getAllUserProgresss(UserProgressFilter filter) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, ExerciseResultEntity> getUserProgressExercise(UserProgressFilter filter) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, KeypointResultEntity> getUserProgressKeypoint(UserProgressFilter filter) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, LessonResultEntity> getUserProgressLesson(UserProgressFilter filter) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(PageBreakRequest request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(Map<String, dynamic> body) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(Map<String, dynamic> body) {
    throw UnimplementedError();
  }
}

class _VideoLessonHarness {
  _VideoLessonHarness({
    required this.cubit,
    required this.userCubit,
    required this.roadmapCubit,
    required this.courseRepository,
    required this.progressRepository,
  });

  final VideoLessonCubit cubit;
  final UserCubit userCubit;
  final CourseRoadmapCubit roadmapCubit;
  final _FakeCourseRepository courseRepository;
  final _FakeProgressRepository progressRepository;
}

void main() {
  group('VideoLessonCubit', () {
    setUp(() async {
      await setupLocaleCubitForTests();
    });

    tearDown(() async {
      await resetInjectorForTests();
    });

    test('opens the zero-second question on the first play gate', () async {
      final harness = _buildHarness(
        learningItem: _learningItem(
          videoQuestions: [
            _videoQuestion(
              atSecond: 0,
              question: _singleChoiceQuestion(
                id: 101,
                prompt: 'Warm-up',
                answers: const ['A', 'B'],
                correctIndex: 0,
              ),
            ),
          ],
        ),
      );
      addTearDown(() async {
        await harness.cubit.close();
        await harness.userCubit.close();
        await harness.roadmapCubit.close();
      });

      await harness.cubit.initialize(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );
      harness.cubit.updatePlaybackProgress(
        position: Duration.zero,
        duration: const Duration(seconds: 30),
      );

      final didOpenQuestion = harness.cubit.maybeTriggerZeroSecondQuestion();

      expect(didOpenQuestion, isTrue);
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.question);
      expect(harness.cubit.state.currentQuestionPrompt?.question.id, 101);
      expect(harness.cubit.state.currentQuestionPrompt?.atSecond, 0);
      expect(harness.cubit.state.resumePlaybackAfterQuestionQueue, isTrue);
      expect(harness.cubit.state.pendingEndAfterQuestionQueue, isFalse);
    });

    test('queues crossed questions during forward seek and lands on the end overlay after the queue drains', () async {
      final harness = _buildHarness(
        learningItem: _learningItem(
          videoQuestions: [
            _videoQuestion(
              atSecond: 5,
              question: _singleChoiceQuestion(
                id: 201,
                prompt: 'Question one',
                answers: const ['A', 'B'],
                correctIndex: 0,
              ),
            ),
            _videoQuestion(
              atSecond: 15,
              question: _singleChoiceQuestion(
                id: 202,
                prompt: 'Question two',
                answers: const ['C', 'D'],
                correctIndex: 1,
              ),
            ),
          ],
        ),
      );
      addTearDown(() async {
        await harness.cubit.close();
        await harness.userCubit.close();
        await harness.roadmapCubit.close();
      });

      await harness.cubit.initialize(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );
      harness.cubit.updatePlaybackProgress(
        position: Duration.zero,
        duration: const Duration(seconds: 20),
      );

      final openedOverlay = harness.cubit.handleForwardSeek(
        fromSecond: 0,
        toSecond: 20,
        wasPlayingBeforeSeek: true,
      );

      expect(openedOverlay, isTrue);
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.question);
      expect(harness.cubit.state.currentQuestionPrompt?.question.id, 201);
      expect(harness.cubit.state.skippedQuestionQueue.map((prompt) => prompt.question.id), [202]);
      expect(harness.cubit.state.pendingEndAfterQuestionQueue, isTrue);

      harness.cubit.selectCurrentQuestionAnswer(0);
      harness.cubit.submitCurrentQuestion();
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.questionResult);

      final resumedAfterFirstQuestion = harness.cubit.continueAfterQuestion();
      expect(resumedAfterFirstQuestion, isFalse);
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.question);
      expect(harness.cubit.state.currentQuestionPrompt?.question.id, 202);

      harness.cubit.selectCurrentQuestionAnswer(1);
      harness.cubit.submitCurrentQuestion();
      final resumedAfterSecondQuestion = harness.cubit.continueAfterQuestion();

      expect(resumedAfterSecondQuestion, isFalse);
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.end);
      expect(harness.cubit.state.questionResults.keys.length, 2);
    });

    test('re-arms future questions on backward seek while preserving earlier results', () async {
      final harness = _buildHarness(
        learningItem: _learningItem(
          videoQuestions: [
            _videoQuestion(
              atSecond: 5,
              question: _singleChoiceQuestion(
                id: 301,
                prompt: 'Past question',
                answers: const ['A', 'B'],
                correctIndex: 0,
              ),
            ),
            _videoQuestion(
              atSecond: 15,
              question: _singleChoiceQuestion(
                id: 302,
                prompt: 'Future question',
                answers: const ['C', 'D'],
                correctIndex: 1,
              ),
            ),
          ],
        ),
      );
      addTearDown(() async {
        await harness.cubit.close();
        await harness.userCubit.close();
        await harness.roadmapCubit.close();
      });

      await harness.cubit.initialize(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );
      harness.cubit.updatePlaybackProgress(
        position: Duration.zero,
        duration: const Duration(seconds: 20),
      );

      harness.cubit.handleForwardSeek(
        fromSecond: 0,
        toSecond: 20,
        wasPlayingBeforeSeek: false,
      );
      harness.cubit.selectCurrentQuestionAnswer(0);
      harness.cubit.submitCurrentQuestion();
      harness.cubit.continueAfterQuestion();
      harness.cubit.selectCurrentQuestionAnswer(1);
      harness.cubit.submitCurrentQuestion();
      harness.cubit.continueAfterQuestion();

      harness.cubit.handleBackwardSeek(
        targetSecond: 10,
        wasPlayingBeforeSeek: false,
      );

      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.none);
      expect(harness.cubit.state.questionResults.keys.length, 1);
      expect(harness.cubit.state.questionResults.values.single.questionId, 301);
      expect(harness.cubit.state.currentQuestionPrompt, isNull);
      expect(harness.cubit.state.currentQuestionResult, isNull);
      expect(harness.cubit.state.skippedQuestionQueue, isEmpty);
    });

    test('keeps completion success while clearing session-only state on exit', () async {
      final harness = _buildHarness(
        learningItem: _learningItem(
          videoQuestions: [
            _videoQuestion(
              atSecond: 0,
              question: _singleChoiceQuestion(
                id: 401,
                prompt: 'Exit question',
                answers: const ['A', 'B'],
                correctIndex: 0,
              ),
            ),
          ],
        ),
      );
      addTearDown(() async {
        await harness.cubit.close();
        await harness.userCubit.close();
        await harness.roadmapCubit.close();
      });

      await harness.cubit.initialize(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );
      harness.cubit.updateNoteDraft('Unsaved draft');
      harness.cubit.maybeTriggerZeroSecondQuestion();
      harness.cubit.selectCurrentQuestionAnswer(0);
      harness.cubit.submitCurrentQuestion();
      harness.cubit.showEndOverlay();

      await harness.cubit.completeLesson();
      harness.cubit.clearSessionStateForExit();

      expect(harness.cubit.state.completionStatus, VideoLessonCompletionStatus.success);
      expect(harness.cubit.state.activeOverlay, VideoLessonOverlay.none);
      expect(harness.cubit.state.noteDraft, isEmpty);
      expect(harness.cubit.state.currentQuestionPrompt, isNull);
      expect(harness.cubit.state.currentQuestionResult, isNull);
      expect(harness.cubit.state.questionResults, isEmpty);
      expect(harness.progressRepository.lastParams?.lessonId, 'lesson-1');
      expect(harness.progressRepository.lastParams?.body['userId'], 'user-1');
      expect(harness.progressRepository.lastParams?.body['courseId'], 'course-1');
      expect(harness.progressRepository.lastParams?.body['passed'], isTrue);
      expect(harness.courseRepository.roadmapLoadCount, 1);
      expect(harness.courseRepository.lastRoadmapCourseId, 'course-1');
    });

    test('falls back to failure when initialization request times out', () async {
      final harness = _buildHarness(
        initializationTimeout: const Duration(milliseconds: 10),
        lessonHandler: (_) => TaskEither.tryCatch(
          () => Completer<LessonEntity>().future,
          (error, stackTrace) => AppException.unexpected(error.toString()),
        ),
      );
      addTearDown(() async {
        await harness.cubit.close();
        await harness.userCubit.close();
        await harness.roadmapCubit.close();
      });

      await harness.cubit.initialize(
        courseId: 'course-1',
        nodeId: 'node-1',
        lessonId: 'lesson-1',
      );

      expect(harness.cubit.state.loadStatus, VideoLessonLoadStatus.failure);
      expect(
        harness.cubit.state.errorMessage,
        'Video lesson is taking too long to load. Please try again.',
      );
    });
  });
}

_VideoLessonHarness _buildHarness({
  LessonEntity? lesson,
  LearningItemEntity? learningItem,
  Duration initializationTimeout = const Duration(seconds: 12),
  TaskEither<AppException, LessonEntity> Function(String lessonId)? lessonHandler,
  TaskEither<AppException, LearningItemEntity> Function(String learningItemId)? learningItemHandler,
}) {
  final courseRepository = _FakeCourseRepository();
  final progressRepository = _FakeProgressRepository();
  final userCubit = _TestUserCubit()..setTestUser(const UserEntity(id: 'user-1'));

  final roadmapCubit = CourseRoadmapCubit(
    GetRoadmapUseCase(courseRepository),
  );

  final videoRepository = _FakeVideoLessonRepository(
    getLearningItemHandler: learningItemHandler ?? (_) => TaskEither.right(learningItem ?? _learningItem()),
  );
  final cubit = VideoLessonCubit(
    GetCourseLessonUseCase(
      _FakeCourseLessonRepository(
        lessonHandler ?? (_) => TaskEither.right(lesson ?? _lesson()),
      ),
    ),
    GetVideoLearningItemUseCase(videoRepository),
    GetAllUserVideoLessonNotesUseCase(videoRepository),
    CreateUserVideoLessonNoteUseCase(videoRepository),
    UpdateUserVideoLessonNoteUseCase(videoRepository),
    DeleteUserVideoLessonNoteUseCase(videoRepository),
    UpdateUserProgressLessonUseCase(progressRepository),
    userCubit,
    roadmapCubit,
  );
  cubit.overrideInitializationTimeout(initializationTimeout);

  return _VideoLessonHarness(
    cubit: cubit,
    userCubit: userCubit,
    roadmapCubit: roadmapCubit,
    courseRepository: courseRepository,
    progressRepository: progressRepository,
  );
}

LessonEntity _lesson() => const LessonEntity(
  id: 'lesson-1',
  courseId: 'course-1',
  learningItemId: 'learning-item-1',
  type: LessonType.video,
  title: BaseMultiLanguage(en: 'Video lesson'),
  video: LessonVideoEntity(url: 'https://example.com/video.mp4'),
);

LearningItemEntity _learningItem({
  List<VideoQuestionEntity> videoQuestions = const [],
}) => LearningItemEntity(
  id: 'learning-item-1',
  videoQuestions: videoQuestions,
);

VideoQuestionEntity _videoQuestion({
  required int atSecond,
  required QuestionEntity question,
}) => VideoQuestionEntity(
  atSecond: atSecond,
  exercise: question,
);

QuestionEntity _singleChoiceQuestion({
  required int id,
  required String prompt,
  required List<String> answers,
  required int correctIndex,
}) => QuestionEntity(
  id: id,
  type: QuestionTypeEnum.singleChoice,
  document: [
    ContentDocumentEntity(
      data: DocumentDataEntity(
        content: BaseMultiLanguage(en: prompt),
      ),
    ),
  ],
  explanation: BaseMultiLanguage(en: 'Explanation for $prompt'),
  typedPayload: QuestionPayloadEntity.singleChoice(
    options: List.generate(
      answers.length,
      (index) => QuestionChoiceOptionEntity(
        value: BaseMultiLanguage(en: answers[index]),
        isCorrect: index == correctIndex,
      ),
    ),
  ),
);
