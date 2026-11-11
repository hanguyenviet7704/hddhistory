// "Bài tôi tạo" must show a run in flight — including the FIRST one, when the
// shelf has no finished lesson to list yet — and it must still know about that
// run after the app has been killed and reopened.
//
// The first half is a layout claim about the page's branch order (an empty list
// plus a running job is not an empty shelf); the second is about the cubit
// remembering the job id across launches, since the polling timer and the state
// both die with the process.
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';

import '../../support/test_di.dart';

/// Never called by these tests — nothing here uploads. A [Fake] so an accidental
/// call throws loudly instead of returning a silent null.
class _FakeUploadRepository extends Fake implements IUploadRepository {}

class _FakeStudyThemeRepository extends Fake implements IStudyThemeRepository {
  @override
  TaskEither<AppException, List<StudyThemePreset>> getStudyThemes() => TaskEither.right(const []);
}

/// The shelf's data: an empty page of lessons (the reported case) unless a test
/// says otherwise, plus whatever job the test wants `getJob` to answer with.
class _FakeImportRepository implements ILearningImportRepository {
  _FakeImportRepository({this.lessons = const [], this.job});

  final List<UserLessonEntity> lessons;

  /// Mutable so a test can let a run finish between polls.
  LearningImportJobEntity? job;

  int getJobCalls = 0;
  int getUserLessonsCalls = 0;
  String? lastRequestedJobId;

  @override
  TaskEither<AppException, ImportQuotaEntity> getQuota() =>
      TaskEither.right(const ImportQuotaEntity(limit: 5, used: 1, remaining: 4, enabled: true));

  @override
  TaskEither<AppException, LearningImportJobEntity> createImport(CreateLearningImportParams params) =>
      TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, LearningImportJobEntity> getJob(String jobId) {
    getJobCalls++;
    lastRequestedJobId = jobId;
    final answer = job;
    if (answer == null) return TaskEither.left(const AppException.unexpected('no job'));
    return TaskEither.right(answer);
  }

  @override
  TaskEither<AppException, BasePageBreak<UserLessonEntity>> getUserLessons({int page = 1, int take = 20}) {
    getUserLessonsCalls++;
    return TaskEither.right(BasePageBreak<UserLessonEntity>(currentPage: 1, totalPages: 1, items: lessons));
  }

  @override
  TaskEither<AppException, UserLessonEntity> getUserLesson(String id) => TaskEither.left(const AppException.unexpected('not used'));

  @override
  TaskEither<AppException, Unit> updateProgress(UpdateLessonProgressParams params) => TaskEither.right(unit);

  @override
  TaskEither<AppException, Unit> requestAdditionalContent(String id) => TaskEither.right(unit);
  @override
  TaskEither<AppException, Unit> deleteUserLesson(String id) => TaskEither.right(unit);
}

/// In-memory stand-in for the Keychain-backed store, so a test can pre-seed "the
/// app was killed while job X was running".
class _InMemoryLocalStore extends Fake implements ILocalStoreService {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String> getString({required String key}) async => values[key] ?? '';

  @override
  Future<void> setString({required String key, required String value}) async => values[key] = value;

  @override
  Future<void> remove({required String key}) async => values.remove(key);
}

/// The key [LearningImportCubit] persists the watched job under. Duplicated here
/// on purpose: it is private to the cubit's library, and a test that hard-codes
/// the string is the thing that notices if the key is ever renamed silently.
const String _kActiveImportJobKey = 'learning_import.active_job';

const _runningJob = LearningImportJobEntity(
  id: 'job_1',
  status: ImportJobStatusEntity.processing,
  percent: 42,
  sourceLabel: 'Chương 3 - Nhiệt động lực học.pdf',
);

void main() {
  late _FakeImportRepository repository;
  late _InMemoryLocalStore store;
  late LearningImportCubit importCubit;
  late UserLessonCubit lessonCubit;

  setUpAll(() async => setupLocaleCubitForTests(locale: AppLocale.vi));

  void buildCubits({List<UserLessonEntity> lessons = const [], LearningImportJobEntity? job}) {
    repository = _FakeImportRepository(lessons: lessons, job: job);
    store = _InMemoryLocalStore();

    if (AppDI.injector.isRegistered<ILocalStoreService>()) {
      AppDI.injector.unregister<ILocalStoreService>();
    }
    AppDI.injector.registerSingleton<ILocalStoreService>(store);

    // The page paints inside ThemedBackground, which reads this cubit straight
    // out of the injector rather than the widget tree.
    if (AppDI.injector.isRegistered<StudyThemeCubit>()) {
      AppDI.injector.unregister<StudyThemeCubit>();
    }
    AppDI.injector.registerSingleton<StudyThemeCubit>(
      StudyThemeCubit(GetStudyThemesUseCase(_FakeStudyThemeRepository())),
    );

    importCubit = LearningImportCubit(
      CreateLearningImportUseCase(repository),
      GetLearningImportJobUseCase(repository),
      GetImportQuotaUseCase(repository),
      UploadCubit(UploadFileUseCase(_FakeUploadRepository())),
    );
    lessonCubit = UserLessonCubit(
      GetUserLessonsUseCase(repository),
      GetUserLessonUseCase(repository),
      UpdateUserLessonProgressUseCase(repository),
      RequestUserLessonAdditionalContentUseCase(repository),
    );
  }

  tearDown(() async {
    await importCubit.close();
    await lessonCubit.close();
  });

  group('MyLessonsPage', () {
    Widget host(Widget child) => TranslationProvider(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider.value(value: importCubit),
              BlocProvider.value(value: lessonCubit),
              // The page's own colours come from the study theme through the
              // tree (`studyThemeScaffoldColor`), while ThemedBackground reads
              // the same cubit out of the injector — both need it.
              BlocProvider.value(value: AppDI.injector.get<StudyThemeCubit>()),
            ],
            child: child,
          ),
        ),
      ),
    );

    testWidgets('shows the run in flight even with no finished lesson yet', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      buildCubits();
      // The reader started an import and walked over to the shelf.
      importCubit.watchJob(_runningJob);

      late String emptyTitle;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              emptyTitle = context.l10n.learningImport.emptyTitle;
              return const MyLessonsPage();
            },
          ),
        ),
      );
      // Two pumps: the first builds, the second lets the (synchronous) fake
      // list request land so the shelf is in its settled state.
      await tester.pump();
      await tester.pump();

      // The generating row, titled with what is being turned into a lesson.
      expect(find.text(_runningJob.sourceLabel), findsOneWidget);
      // And NOT the "you have nothing" screen, which is what used to win here.
      expect(find.text(emptyTitle), findsNothing);
      expect(tester.takeException(), isNull);

      // Watching a job means a 3s poll timer, which the real cubit only stops on
      // a terminal poll — and the test harness fails a test that leaves a timer
      // pending. Stop it here rather than pretending the job ended.
      importCubit.reset();
      await tester.pump();
    });

    testWidgets('asks the list again when the run finishes while the shelf is open', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      buildCubits(job: _runningJob);
      importCubit.watchJob(_runningJob);

      await tester.pumpWidget(host(const MyLessonsPage()));
      await tester.pump();
      await tester.pump();
      expect(repository.getUserLessonsCalls, 1);

      // The next poll finds it finished. The finished lesson is on the server
      // but not in the page fetched on entry, so the shelf has to re-ask.
      repository.job = const LearningImportJobEntity(
        id: 'job_1',
        status: ImportJobStatusEntity.completed,
        percent: 100,
        userLessonId: 'lesson_1',
      );
      await importCubit.refreshActiveJob();
      await tester.pump();
      await tester.pump();

      expect(repository.getUserLessonsCalls, 2);
    });

    testWidgets('still shows the empty state when nothing is generating', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      buildCubits();

      late String emptyTitle;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) {
              emptyTitle = context.l10n.learningImport.emptyTitle;
              return const MyLessonsPage();
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text(emptyTitle), findsOneWidget);
    });
  });

  group('LearningImportCubit.refreshActiveJob', () {
    test('picks the run back up from disk when the app was killed', () async {
      buildCubits(job: _runningJob);
      store.values[_kActiveImportJobKey] = _runningJob.id;

      // A fresh launch: nothing in memory.
      expect(importCubit.state.job, isNull);

      await importCubit.refreshActiveJob();

      expect(repository.lastRequestedJobId, _runningJob.id);
      expect(importCubit.state.job?.id, _runningJob.id);
      expect(importCubit.state.job?.percent, 42);
      // Still running, so the id must stay for the NEXT launch too.
      expect(store.values[_kActiveImportJobKey], _runningJob.id);
    });

    test('forgets the id and leaves the announcement to the popup when the restored run had finished', () async {
      buildCubits(
        job: const LearningImportJobEntity(
          id: 'job_1',
          status: ImportJobStatusEntity.completed,
          percent: 100,
          userLessonId: 'lesson_1',
        ),
      );
      store.values[_kActiveImportJobKey] = 'job_1';

      await importCubit.refreshActiveJob();

      expect(importCubit.state.job?.isDone, isTrue);
      expect(store.values.containsKey(_kActiveImportJobKey), isFalse);
      // The done popup is the one surface that tells them; the shell toast must
      // not say the same thing a dialog later.
      expect(importCubit.state.toastDismissed, isTrue);
    });

    test('asks nothing when no run was ever saved', () async {
      buildCubits(job: _runningJob);

      await importCubit.refreshActiveJob();

      expect(repository.getJobCalls, 0);
      expect(importCubit.state.job, isNull);
    });
  });
}
