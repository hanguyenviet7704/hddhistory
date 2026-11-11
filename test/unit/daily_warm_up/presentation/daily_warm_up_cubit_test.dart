import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../../support/test_di.dart';

class _FakeDailyWarmUpRepository implements IDailyWarmUpRepository {
  _FakeDailyWarmUpRepository(this.result);

  TaskEither<AppException, DailyWarmUpEntity> result;
  int callCount = 0;

  @override
  TaskEither<AppException, DailyWarmUpEntity> getDailyWarmUp() {
    callCount += 1;
    return result;
  }
}

class _FakeDailyWarmUpLocalDataSource implements DailyWarmUpLocalDataSource {
  final Map<String, String> shownDates = {};
  final Map<String, String> onboardingCompletedDates = {};

  @override
  Future<void> cacheDailyWarmUp(DailyWarmUpModel model) async {}

  @override
  Future<void> clearCache() async {}

  @override
  Future<DailyWarmUpModel?> getCachedDailyWarmUp() async => null;

  @override
  Future<String> getShownDate(String userId) async => shownDates[userId] ?? '';

  @override
  Future<String> getOnboardingCompletedDate(String userId) async => onboardingCompletedDates[userId] ?? '';

  @override
  Future<void> markShownDate(String userId, String date) async {
    shownDates[userId] = date;
  }

  @override
  Future<void> markOnboardingCompletedDateIfAbsent(String userId, String date) async {
    onboardingCompletedDates.putIfAbsent(userId, () => date);
  }
}

class _FakeCourseRepository implements ICourseRepository {
  _FakeCourseRepository({this.courseResult});

  TaskEither<AppException, CourseEntity>? courseResult;

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    return courseResult ??
        TaskEither.right(
          CourseEntity(
            id: id,
            title: BaseMultiLanguage(en: 'Course $id'),
          ),
        );
  }

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, List<String>> getSearchHistory() {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, Unit> saveSearchQuery(String query) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, Unit> clearSearchHistory() {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, List<CourseEntity>> getRecentCourses() {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, Unit> recordCourseView(String courseId) {
    throw UnimplementedError();
  }

  @override
  TaskEither<AppException, Unit> clearRecentCourses() {
    throw UnimplementedError();
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    AppDI.injector.registerSingleton<ITrackingService>(
      AppTrackingService(NoOpTrackingService()),
    );
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('DailyWarmUpCubit', () {
    test('Given warm-up already shown today, When Home checks entry, Then API is not called', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.shownDates['user-1'] = '2026-05-22';
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(repository.callCount, 0);
      expect(cubit.state.status, DailyWarmUpStatus.initial);
    });

    test('Given API failure, When Home checks entry, Then P1 is skipped and shown date is not marked', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.left(const AppException.connection('offline'))),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(cubit.state.status, DailyWarmUpStatus.closed);
      expect(localDataSource.shownDates, isEmpty);
    });

    test('Given invalid entry data, When loaded for Home, Then P1 is skipped and shown date is not marked', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(const DailyWarmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(cubit.state.canShowEntry, isFalse);
      expect(localDataSource.shownDates, isEmpty);
    });

    test('Given only unsupported questions, When loaded for Home, Then P1 is skipped', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity(questions: [_speakingQuestion()]))),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(cubit.state.canShowEntry, isFalse);
      expect(localDataSource.shownDates, isEmpty);
    });

    test('Given valid entry data, When P1 is rendered, Then shown date is marked per user', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      await cubit.markEntryPresented();

      expect(canOpen, isTrue);
      expect(cubit.state.canShowEntry, isTrue);
      expect(localDataSource.shownDates['user-1'], '2026-05-22');
    });

    test('Given P1 is dismissed with maybe later, When flow closes, Then shown date remains marked', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';
      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      await cubit.dismissEntry();

      expect(cubit.state.status, DailyWarmUpStatus.closed);
      expect(localDataSource.shownDates['user-1'], '2026-05-22');
    });

    test('Given final question result, When continuing, Then completion step opens without backend progress', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource()..onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);
      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      cubit.startWarmUp();
      cubit.selectChoiceAnswer(0);

      await cubit.checkCurrentQuestion();
      await cubit.continueFromResult();

      expect(cubit.state.status, DailyWarmUpStatus.completion);
      expect(cubit.state.results, hasLength(1));
      expect(cubit.state.correctCount, 1);
    });

    test('Given suggested course load fails, When completion loads course, Then flow closes silently', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource()..onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
        courseRepository: _FakeCourseRepository(
          courseResult: TaskEither.left(const AppException.notFound('missing')),
        ),
      );
      addTearDown(cubit.close);
      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      cubit.startWarmUp();
      cubit.showCompletion();

      await cubit.loadSuggestedCourse();

      expect(cubit.state.status, DailyWarmUpStatus.closed);
      expect(cubit.state.suggestedCourse, isNull);
    });

    test('Given roadmap helper falls back to catalog, When starting today lesson, Then handoff fails', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource()..onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);
      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      cubit.showCompletion();
      await cubit.loadSuggestedCourse();

      final didPrepareRoadmap = await cubit.startTodayLesson(
        prepareCourse: (_) async => CourseHandoffRouteIntent.course,
      );

      expect(didPrepareRoadmap, isFalse);
      expect(cubit.state.isRoutingToRoadmap, isFalse);
    });

    test('Given route handoff is running, When primary CTA is tapped again, Then second tap is ignored', () async {
      final localDataSource = _FakeDailyWarmUpLocalDataSource()..onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(
        repository: _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity())),
        localDataSource: localDataSource,
      );
      addTearDown(cubit.close);
      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      cubit.showCompletion();
      await cubit.loadSuggestedCourse();
      var prepareCount = 0;

      final firstTap = cubit.startTodayLesson(
        prepareCourse: (_) async {
          prepareCount += 1;
          await Future<void>.delayed(const Duration(milliseconds: 1));
          return CourseHandoffRouteIntent.courseRoadmap;
        },
      );
      final secondTap = await cubit.startTodayLesson(
        prepareCourse: (_) async {
          prepareCount += 1;
          return CourseHandoffRouteIntent.courseRoadmap;
        },
      );
      final firstResult = await firstTap;

      expect(firstResult, isTrue);
      expect(secondTap, isFalse);
      expect(prepareCount, 1);
    });

    test('Given onboarding is incomplete, When Home checks entry, Then API is skipped and shown date is not marked', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: false,
      );

      expect(canOpen, isFalse);
      expect(repository.callCount, 0);
      expect(localDataSource.shownDates, isEmpty);
      expect(localDataSource.onboardingCompletedDates, isEmpty);
    });

    test('Given first completed-onboarding day, When Home checks entry, Then date is marked and API is skipped', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(repository.callCount, 0);
      expect(localDataSource.shownDates, isEmpty);
      expect(localDataSource.onboardingCompletedDates['user-1'], '2026-05-22');
    });

    test('Given first completed-onboarding day was skipped, When Home refreshes same app session, Then API remains skipped', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );
      final canOpenAfterRefresh = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpenAfterRefresh, isFalse);
      expect(repository.callCount, 0);
      expect(localDataSource.shownDates, isEmpty);
      expect(localDataSource.onboardingCompletedDates['user-1'], '2026-05-22');
    });

    test('Given app restarts on first completed-onboarding day, When Home checks entry, Then API remains skipped', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-22';
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(repository.callCount, 0);
      expect(localDataSource.shownDates, isEmpty);
    });

    test('Given next local day after completed onboarding, When Home checks entry, Then API can load warm-up', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-22';
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-23',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isTrue);
      expect(repository.callCount, 1);
      expect(localDataSource.shownDates, isEmpty);
      expect(cubit.state.canShowEntry, isTrue);
    });

    test('Given onboarding date exists for one user, When another user checks entry, Then second user still skips first day', () async {
      final repository = _FakeDailyWarmUpRepository(TaskEither.right(_warmUpEntity()));
      final localDataSource = _FakeDailyWarmUpLocalDataSource();
      localDataSource.onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = _buildCubit(repository: repository, localDataSource: localDataSource);
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-2',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      expect(canOpen, isFalse);
      expect(repository.callCount, 0);
      expect(localDataSource.onboardingCompletedDates['user-1'], '2026-05-21');
      expect(localDataSource.onboardingCompletedDates['user-2'], '2026-05-22');
    });
  });
}

DailyWarmUpCubit _buildCubit({
  required _FakeDailyWarmUpRepository repository,
  _FakeDailyWarmUpLocalDataSource? localDataSource,
  _FakeCourseRepository? courseRepository,
}) {
  return DailyWarmUpCubit(
    GetDailyWarmUpUseCase(repository),
    localDataSource ?? _FakeDailyWarmUpLocalDataSource(),
    GetCourseUseCase(courseRepository ?? _FakeCourseRepository()),
  );
}

DailyWarmUpEntity _warmUpEntity({List<QuestionEntity>? questions}) {
  return DailyWarmUpEntity(
    courseId: 'course-1',
    suggestedCourseId: 'course-2',
    lessonId: 'lesson-1',
    keypointId: 'keypoint-1',
    questions:
        questions ??
        [
          QuestionEntity(
            id: 1,
            document: [_document('Pick one')],
            typedPayload: QuestionPayloadEntity.singleChoice(
              options: [
                QuestionChoiceOptionEntity(value: _text('A'), isCorrect: true),
                QuestionChoiceOptionEntity(value: _text('B')),
              ],
            ),
          ),
        ],
  );
}

ContentDocumentEntity _document(String text) {
  return ContentDocumentEntity(data: DocumentDataEntity(content: _text(text)));
}

QuestionEntity _speakingQuestion() {
  return QuestionEntity(
    id: 2,
    type: QuestionTypeEnum.speaking,
    document: [_document('Speak')],
    typedPayload: const QuestionPayloadEntity.speaking(record: 'audio.mp3'),
  );
}

BaseMultiLanguage _text(String value) => BaseMultiLanguage(en: value, vi: value, zh: value);
