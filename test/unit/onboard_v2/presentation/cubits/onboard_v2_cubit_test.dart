import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';
import 'package:mockito/mockito.dart';

import '../../../../support/test_di.dart';

class _MockAuthBloc extends Mock implements AuthBloc {}

class _MockUserCubit extends Mock implements UserCubit {}

class _FakeDeviceInfoService implements IDeviceInfoService {
  @override
  Future<String> get deviceName async => 'iPhone';

  @override
  Future<String> get deviceToken async => 'device-token';

  @override
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

class _FakeOnboardRepository implements IOnboardRepository {
  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() {
    return TaskEither.right(
      const OnboardEntity(
        age: [
          OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')),
        ],
      ),
    );
  }

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) => TaskEither.right(const UserEntity());
}

class _FakeProfileRepository implements IProfileRepository {
  _FakeProfileRepository({this.updateCompleter});

  final Completer<UserEntity>? updateCompleter;
  Map<String, dynamic>? lastParams;
  int updateCount = 0;
  bool hasCompletedUpdate = false;

  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity(id: 'user_1'));

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) {
    return TaskEither(() async {
      lastParams = Map<String, dynamic>.from(params);
      updateCount += 1;
      final completer = updateCompleter;
      if (completer != null) {
        final user = await completer.future;
        hasCompletedUpdate = true;
        return right(user);
      }
      hasCompletedUpdate = true;
      return right(UserEntity(id: params['id'] as String? ?? ''));
    });
  }
}

class _FakeCourseRepository implements ICourseRepository {
  _FakeCourseRepository({
    this.courses = const [],
    this.failDetail = false,
  });

  final List<CourseEntity> courses;
  final bool failDetail;
  int listCount = 0;
  PageBreakRequest<CourseFilterRequest>? lastRequest;

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    listCount += 1;
    lastRequest = request;
    return TaskEither.right(BasePageBreak<CourseEntity>(items: courses));
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    if (failDetail) return TaskEither.left(const AppException.notFound('missing course'));
    return TaskEither.right(CourseEntity(id: id, numberOfLesson: 1));
  }

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

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('OnboardV2Cubit', () {
    test('initialize loads age data and starts anonymous login without skillset preload dependency', () async {
      final events = <String>[];
      Map<String, dynamic>? loginPayload;
      var hasAnonymousSession = false;
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => hasAnonymousSession,
        loginAnonymousSilently: (payload) async {
          events.add('login');
          loginPayload = Map<String, dynamic>.from(payload);
          hasAnonymousSession = true;
          return true;
        },
      );

      await cubit.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.onboardStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.onboardData.age, isNotEmpty);
      expect(events, ['login']);
      expect(loginPayload?.keys, unorderedEquals(['device', 'language']));
      expect(loginPayload?.containsKey('name'), isFalse);
      expect(loginPayload?.containsKey('age'), isFalse);

      await cubit.close();
    });

    test('P3 submit moves to P4 notification before profile update finishes', () async {
      final updateCompleter = Completer<UserEntity>();
      final profileRepository = _FakeProfileRepository(updateCompleter: updateCompleter);
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        hasActiveAnonymousSession: () => true,
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      cubit.updateName('  Alice  ');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Notification);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);
      await Future<void>.delayed(Duration.zero);
      expect(profileRepository.updateCount, 1);
      expect(profileRepository.lastParams, containsPair('id', 'user_1'));
      expect(profileRepository.lastParams, containsPair('name', 'Alice'));
      expect(profileRepository.lastParams, containsPair('age', '18-24'));
      expect(profileRepository.hasCompletedUpdate, isFalse);

      updateCompleter.complete(const UserEntity(id: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      expect(profileRepository.hasCompletedUpdate, isTrue);

      await cubit.close();
    });

    test('P4 and P8 block Cubit back navigation', () async {
      final courseRepository = _FakeCourseRepository(
        courses: const [CourseEntity(id: 'course_1', numberOfLesson: 1)],
      );
      final cubit = _buildCubit(courseRepository: courseRepository);

      cubit.updateName('Alice');
      cubit.continueFromName();
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();
      cubit.goBack();
      expect(cubit.state.currentPage, OnboardV2PageStep.p4Notification);

      cubit.continueFromP4Notification(notificationStatus: OnboardV2NotificationStatus.maybeLater);
      cubit.togglePath(OnboardingPath.feelBetter);
      cubit.continueFromP5Paths();
      cubit.continueFromP6PathMap();
      cubit.toggleSymptom(OnboardingSymptom.motivationDisappears);
      await cubit.continueFromP7Symptoms();
      cubit.goBack();

      expect(cubit.state.currentPage, OnboardV2PageStep.p8CoursePicker);

      await cubit.close();
    });

    test('path selection caps at two and recomputes available symptoms', () async {
      final cubit = _buildCubit();

      cubit.togglePath(OnboardingPath.feelBetter);
      cubit.toggleSymptom(OnboardingSymptom.motivationDisappears);
      cubit.togglePath(OnboardingPath.thinkBetter);
      cubit.togglePath(OnboardingPath.workBetter);

      expect(cubit.state.selectedPaths, [OnboardingPath.feelBetter, OnboardingPath.thinkBetter]);
      expect(cubit.state.availableSymptoms, contains(OnboardingSymptom.motivationDisappears));
      expect(cubit.state.availableSymptoms, contains(OnboardingSymptom.overthinking));

      cubit.togglePath(OnboardingPath.feelBetter);
      expect(cubit.state.selectedPaths, [OnboardingPath.thinkBetter]);
      expect(cubit.state.selectedSymptoms, isEmpty);
      expect(cubit.state.availableSymptoms, isNot(contains(OnboardingSymptom.motivationDisappears)));

      await cubit.close();
    });

    test('P7 cannot load courses with zero selected symptoms', () async {
      final courseRepository = _FakeCourseRepository();
      final cubit = _buildCubit(courseRepository: courseRepository);

      cubit.togglePath(OnboardingPath.feelBetter);
      await cubit.continueFromP7Symptoms();

      expect(courseRepository.listCount, 0);
      expect(cubit.state.currentPage, OnboardV2PageStep.p1Intro);

      await cubit.close();
    });

    test('P8 course loading uses selected symptoms and keeps max three valid courses', () async {
      final courseRepository = _FakeCourseRepository(
        courses: const [
          CourseEntity(id: '', numberOfLesson: 4),
          CourseEntity(id: 'course_1', numberOfLesson: 1),
          CourseEntity(id: 'course_2', numberOfLesson: 0),
          CourseEntity(id: 'course_3', numberOfLesson: 3),
          CourseEntity(id: 'course_4', numberOfLesson: 4),
          CourseEntity(id: 'course_5', numberOfLesson: 5),
        ],
      );
      final cubit = _buildCubit(courseRepository: courseRepository);

      cubit.continueFromP4Notification(notificationStatus: OnboardV2NotificationStatus.maybeLater);
      cubit.togglePath(OnboardingPath.feelBetter);
      cubit.continueFromP5Paths();
      cubit.continueFromP6PathMap();
      cubit.toggleSymptom(OnboardingSymptom.motivationDisappears);
      cubit.toggleSymptom(OnboardingSymptom.endlessScrollingFeelsEmpty);
      await cubit.continueFromP7Symptoms();

      expect(cubit.state.currentPage, OnboardV2PageStep.p8CoursePicker);
      expect(cubit.state.courseStatus, OnboardV2CourseStatus.loaded);
      expect(cubit.state.recommendedCourses, hasLength(3));
      expect(cubit.state.recommendedCourses.every((course) => course.id.isNotEmpty && course.numberOfLesson > 0), isTrue);
      expect(courseRepository.lastRequest?.filter?.onboardingSymptoms, [
        OnboardingSymptom.motivationDisappears,
        OnboardingSymptom.endlessScrollingFeelsEmpty,
      ]);

      await cubit.close();
    });

    test('detail failure keeps user on P8 fallback and does not mark navigation success', () async {
      final courseRepository = _FakeCourseRepository(failDetail: true);
      final cubit = _buildCubit(courseRepository: courseRepository);

      final result = await cubit.resolveCourseForHandoff(const CourseEntity(id: 'course_1', numberOfLesson: 1));

      expect(result, isNull);
      expect(cubit.state.courseStatus, OnboardV2CourseStatus.fallback);
      expect(cubit.state.navigationStatus, OnboardV2NavigationStatus.failure);

      await cubit.close();
    });

    test('marks user onboarded in background with existing name', () async {
      final profileRepository = _FakeProfileRepository();
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        readUserState: () => const UserState(
          auth: AuthEntity(
            user: UserEntity(id: 'user_1', name: 'Saved Name'),
          ),
        ),
      );

      cubit.updateName('  Alice  ');
      cubit.markUserOnboardedInBackground();
      await Future<void>.delayed(Duration.zero);

      expect(profileRepository.updateCount, 1);
      expect(profileRepository.lastParams, containsPair('id', 'user_1'));
      expect(profileRepository.lastParams, containsPair('name', 'Alice'));
      expect(profileRepository.lastParams, containsPair('isOnboarded', true));

      await cubit.close();
    });
  });
}

OnboardV2Cubit _buildCubit({
  AuthBloc? authBloc,
  UserCubit? userCubit,
  IProfileRepository? profileRepository,
  ICourseRepository? courseRepository,
  bool Function()? hasActiveAnonymousSession,
  Future<bool> Function(Map<String, dynamic> payload)? loginAnonymousSilently,
  UserState Function()? readUserState,
}) {
  final effectiveCourseRepository = courseRepository ?? _FakeCourseRepository();
  return OnboardV2Cubit.withRandom(
    GetAllOnboardsUseCase(_FakeOnboardRepository()),
    UpdateUserUseCase(profileRepository ?? _FakeProfileRepository()),
    GetAllCoursesUseCase(effectiveCourseRepository),
    GetCourseUseCase(effectiveCourseRepository),
    _FakeDeviceInfoService(),
    authBloc ?? _MockAuthBloc(),
    userCubit ?? _MockUserCubit(),
    AppDI.injector.get<LocaleCubit>(),
    Random(0),
    hasActiveAnonymousSession: hasActiveAnonymousSession ?? () => false,
    loginAnonymousSilently: loginAnonymousSilently ?? (_) async => true,
    readUserState: readUserState ?? () => const UserState(),
  );
}
