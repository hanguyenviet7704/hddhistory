import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

typedef _Harness = ({
  ProgressCubit cubit,
  CourseLessonCubit lessonCubit,
  HomeCubit homeCubit,
  CourseRoadmapCubit roadmapCubit,
  RoleplayCubit roleplayCubit,
  _TestUserCubit userCubit,
});

class _FakeProgressRepository implements IProgressRepository {
  _FakeProgressRepository(this.getAllHandler);

  final TaskEither<AppException, UserProgressEntity> Function(UserProgressFilter filter) getAllHandler;

  @override
  TaskEither<AppException, UserProgressEntity> getAllUserProgresss(UserProgressFilter filter) => getAllHandler(filter);
  @override
  TaskEither<AppException, LessonResultEntity> getUserProgressLesson(UserProgressFilter filter) => TaskEither.right(const LessonResultEntity());
  @override
  TaskEither<AppException, KeypointResultEntity> getUserProgressKeypoint(UserProgressFilter filter) => TaskEither.right(const KeypointResultEntity());
  @override
  TaskEither<AppException, ExerciseResultEntity> getUserProgressExercise(UserProgressFilter filter) => TaskEither.right(const ExerciseResultEntity());
  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressLesson(String lessonId, Map<String, dynamic> body) => TaskEither.right(const UserProgressEntity());
  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressKeypoint(Map<String, dynamic> body) => TaskEither.right(const UserProgressEntity());
  @override
  TaskEither<AppException, UserProgressEntity> updateUserProgressExercise(Map<String, dynamic> body) => TaskEither.right(const UserProgressEntity());
  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getUserProgressMyCourses(PageBreakRequest request) => TaskEither.right(const BasePageBreak<CourseEntity>());
}

class _FakeContentRequestRepository implements IContentRequestRepository {
  @override
  TaskEither<AppException, UserProgressEntity> createCompletedLevelAdditionalContentRequest(Map<String, dynamic> body) => TaskEither.right(const UserProgressEntity());
}

class _FakeHomeRepository implements IHomeRepository {
  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(PageBreakRequest<SkillsetFilterRequest> request) =>
      TaskEither.right(const BasePageBreak<SkillsetEntity>());
  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) => TaskEither.right(const SkillsetEntity());
  @override
  TaskEither<AppException, QuoteEntity> getRandomQuote() => TaskEither.right(const QuoteEntity());
  @override
  TaskEither<AppException, List<SuggestedCourseEntity>> getSuggestCourses(int limit) => TaskEither.right(const []);
}

class _FakeCourseRepository implements ICourseRepository {
  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) => TaskEither.right(const BasePageBreak<CourseEntity>());
  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) => TaskEither.right(const CourseEntity());
  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) => TaskEither.right(const RoadmapEntity());
  @override
  TaskEither<AppException, List<String>> getSearchHistory() => TaskEither.right(const []);
  @override
  TaskEither<AppException, Unit> saveSearchQuery(String query) => TaskEither.right(unit);
  @override
  TaskEither<AppException, Unit> clearSearchHistory() => TaskEither.right(unit);
  @override
  TaskEither<AppException, List<CourseEntity>> getRecentCourses() => TaskEither.right(const []);
  @override
  TaskEither<AppException, Unit> recordCourseView(String courseId) => TaskEither.right(unit);
  @override
  TaskEither<AppException, Unit> clearRecentCourses() => TaskEither.right(unit);
}

class _FakeCourseLessonRepository implements ICourseLessonRepository {
  @override
  TaskEither<AppException, BasePageBreak<LessonEntity>> getAllCourseLessons(PageBreakRequest request) => TaskEither.right(const BasePageBreak<LessonEntity>());
  @override
  TaskEither<AppException, LessonEntity> getCourseLesson(String id) => TaskEither.right(const LessonEntity());
}

class _FakeRoleplayRepository implements IRoleplayRepository {
  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) => TaskEither.right(const LearningItemEntity());
  @override
  TaskEither<AppException, RoleplayFeedbackEntity> sendFeedbackRoleplay(Map<String, dynamic> body) => TaskEither.right(const RoleplayFeedbackEntity());
}

class _FakeRemoteConfigService implements IRemoteConfigService {
  @override
  AppFunctionEntity get appFunction => const AppFunctionEntity();
  @override
  AppVersionConfigEntity get appVersionConfig => const AppVersionConfigEntity();
  @override
  CourseConfigEntity get courseConfig => const CourseConfigEntity();
  @override
  OnboardingConfigEntity get onboardingConfig => const OnboardingConfigEntity();
  @override
  PaywallConfigEntity get paywallConfig => const PaywallConfigEntity();
  @override
  Future<void> initialize() async {}  @override
  Future<bool> updateAvailable() async => false;
}

class _FakeTrackingService extends BaseTrackingService {}

class _TestUserCubit extends UserCubit {
  _TestUserCubit() : super(_FakeTrackingService());

  void setUserIdForTest(String id) {
    emit(
      state.copyWith(
        auth: AuthEntity(user: UserEntity(id: id)),
      ),
    );
  }
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('ProgressCubit course progress loading', () {
    test('omits selected lesson from course-grade progress filter', () async {
      UserProgressFilter? capturedFilter;
      final harness = _buildHarness(
        _FakeProgressRepository((filter) {
          capturedFilter = filter;
          return TaskEither.right(const UserProgressEntity(courseId: 'course-1'));
        }),
      );
      harness.userCubit.setUserIdForTest('user-1');
      harness.lessonCubit.setSelectedLesson(const LessonEntity(id: 'lesson-stale'));

      await harness.cubit.loadAllUserProgresss(courseId: 'course-1');

      expect(capturedFilter?.userId, 'user-1');
      expect(capturedFilter?.courseId, 'course-1');
      expect(capturedFilter?.grade, UserProgressFilterType.course);
      expect(capturedFilter?.lessonId, isNull);

      await _closeHarness(harness);
    });

    test('ignores stale course progress response when a newer load completes first', () async {
      final firstCompleter = Completer<UserProgressEntity>();
      final secondCompleter = Completer<UserProgressEntity>();
      final harness = _buildHarness(
        _FakeProgressRepository((filter) {
          final future = filter.courseId == 'course-a' ? firstCompleter.future : secondCompleter.future;
          return TaskEither.tryCatch(
            () async => future,
            (error, _) => AppException.unexpected(error.toString()),
          );
        }),
      );
      harness.userCubit.setUserIdForTest('user-1');

      final firstLoad = harness.cubit.loadAllUserProgresss(courseId: 'course-a', silent: true);
      final secondLoad = harness.cubit.loadAllUserProgresss(courseId: 'course-b', silent: true);

      secondCompleter.complete(const UserProgressEntity(courseId: 'course-b'));
      await secondLoad;
      expect(harness.cubit.state.userCourseProgress.courseId, 'course-b');

      firstCompleter.complete(const UserProgressEntity(courseId: 'course-a'));
      await firstLoad;
      expect(harness.cubit.state.userCourseProgress.courseId, 'course-b');

      await _closeHarness(harness);
    });
  });
}

_Harness _buildHarness(_FakeProgressRepository progressRepository) {
  final homeCubit = HomeCubit(
    GetAllSkillsetsUseCase(_FakeHomeRepository()),
    GetSkillsetUseCase(_FakeHomeRepository()),
    GetRandomQuoteUseCase(_FakeHomeRepository()),
    GetSuggestCoursesUseCase(_FakeHomeRepository()),
  );
  final lessonCubit = CourseLessonCubit(GetCourseLessonUseCase(_FakeCourseLessonRepository()), _FakeRemoteConfigService());
  final roadmapCubit = CourseRoadmapCubit(GetRoadmapUseCase(_FakeCourseRepository()));
  final roleplayCubit = RoleplayCubit(GetRoleplayLearningItemUseCase(_FakeRoleplayRepository()), SendFeedbackRoleplayUseCase(_FakeRoleplayRepository()));
  final userCubit = _TestUserCubit();
  final cubit = ProgressCubit(
    GetAllUserProgresssUseCase(progressRepository),
    GetUserProgressLessonUseCase(progressRepository),
    GetUserProgressKeypointUseCase(progressRepository),
    GetUserProgressExerciseUseCase(progressRepository),
    UpdateUserProgressLessonUseCase(progressRepository),
    UpdateUserProgressKeypointUseCase(progressRepository),
    UpdateUserProgressExerciseUseCase(progressRepository),
    GetUserProgressMyCoursesUseCase(progressRepository),
    CreateCompletedLevelAdditionalContentRequestUseCase(_FakeContentRequestRepository()),
    homeCubit,
    lessonCubit,
    roadmapCubit,
    userCubit,
    roleplayCubit,
  );

  return (cubit: cubit, lessonCubit: lessonCubit, homeCubit: homeCubit, roadmapCubit: roadmapCubit, roleplayCubit: roleplayCubit, userCubit: userCubit);
}

Future<void> _closeHarness(_Harness harness) async {
  await harness.cubit.close();
  await harness.lessonCubit.close();
  await harness.homeCubit.close();
  await harness.roadmapCubit.close();
  await harness.roleplayCubit.close();
  await harness.userCubit.close();
}
