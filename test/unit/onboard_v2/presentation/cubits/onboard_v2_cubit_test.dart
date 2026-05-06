import 'package:flutter_test/flutter_test.dart';
import 'package:device_info_plus/device_info_plus.dart';
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
  _FakeOnboardRepository(this.onboard);

  final OnboardEntity onboard;

  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() => TaskEither.right(onboard);

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) => TaskEither.right(const UserEntity());
}

class _FakeHomeRepository implements IHomeRepository {
  _FakeHomeRepository({
    this.failuresBeforeSuccess = 0,
    this.skillsets = const [],
    this.onGetAllSkillsets,
  });

  final int failuresBeforeSuccess;
  final List<SkillsetEntity> skillsets;
  final void Function()? onGetAllSkillsets;
  int callCount = 0;

  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(PageBreakRequest<SkillsetFilterRequest> request) {
    callCount += 1;
    onGetAllSkillsets?.call();
    if (callCount <= failuresBeforeSuccess) {
      return TaskEither.left(const AppException.unauthorized('login required'));
    }
    return TaskEither.right(BasePageBreak<SkillsetEntity>(items: skillsets));
  }

  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) => TaskEither.right(const SkillsetEntity());
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
    this.courseDetail = const CourseEntity(),
    this.listCompleter,
  });

  final CourseEntity courseDetail;
  final Completer<BasePageBreak<CourseEntity>>? listCompleter;
  int listCount = 0;

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    listCount += 1;
    final completer = listCompleter;
    if (completer != null) {
      return TaskEither(() async => right(await completer.future));
    }
    return TaskEither.right(BasePageBreak<CourseEntity>());
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) {
    if (courseDetail.id.isEmpty) return TaskEither.left(const AppException.notFound('missing course'));
    return TaskEither.right(courseDetail);
  }

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) => TaskEither.right(const RoadmapEntity());
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('OnboardV2Cubit', () {
    test('initialize starts anonymous login and skillset preload from P1', () async {
      final events = <String>[];
      var hasAnonymousSession = false;
      Map<String, dynamic>? loginPayload;
      final homeRepository = _FakeHomeRepository(
        skillsets: const [SkillsetEntity(id: 'skill_1')],
        onGetAllSkillsets: () => events.add('skillsets'),
      );
      final cubit = _buildCubit(
        homeRepository: homeRepository,
        hasActiveAnonymousSession: () => hasAnonymousSession,
        loginAnonymousSilently: (payload) async {
          events.add('login');
          loginPayload = Map<String, dynamic>.from(payload);
          hasAnonymousSession = true;
          return true;
        },
      );

      await cubit.initialize();
      await cubit.loadSkillsets();

      expect(cubit.state.onboardStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsets.single.id, 'skill_1');
      expect(homeRepository.callCount, 1);
      expect(events, ['login', 'skillsets']);
      expect(loginPayload?.keys, unorderedEquals(['device', 'language']));
      expect(loginPayload?.containsKey('name'), isFalse);
      expect(loginPayload?.containsKey('age'), isFalse);

      await cubit.close();
    });

    test('accepts existing anonymous session and starts profile update without blocking P4', () async {
      final profileRepository = _FakeProfileRepository();
      var loginCount = 0;

      final cubit = _buildCubit(
        profileRepository: profileRepository,
        hasActiveAnonymousSession: () => true,
        loginAnonymousSilently: (_) async {
          loginCount += 1;
          return true;
        },
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      cubit.updateName('  Alice  ');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();
      await Future<void>.delayed(Duration.zero);

      expect(loginCount, 0);
      expect(profileRepository.updateCount, 1);
      expect(profileRepository.lastParams, containsPair('id', 'user_1'));
      expect(profileRepository.lastParams, containsPair('name', 'Alice'));
      expect(profileRepository.lastParams, containsPair('age', '18-24'));
      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);

      await cubit.close();
    });

    test('moves to P4 before profile update finishes', () async {
      final updateCompleter = Completer<UserEntity>();
      final profileRepository = _FakeProfileRepository(updateCompleter: updateCompleter);
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        hasActiveAnonymousSession: () => true,
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);
      await Future<void>.delayed(Duration.zero);
      expect(profileRepository.updateCount, 1);
      expect(profileRepository.hasCompletedUpdate, isFalse);

      updateCompleter.complete(const UserEntity(id: 'user_1'));
      await Future<void>.delayed(Duration.zero);
      expect(profileRepository.hasCompletedUpdate, isTrue);

      await cubit.close();
    });

    test('moves to P4 and exposes skillset failure when anonymous login fails', () async {
      final profileRepository = _FakeProfileRepository();
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) async => false,
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();
      await cubit.loadSkillsets();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.failure);
      expect(profileRepository.updateCount, 0);

      await cubit.close();
    });

    test('moves to P4 and skips profile update when current user id is missing', () async {
      final profileRepository = _FakeProfileRepository();
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        hasActiveAnonymousSession: () => true,
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.p3ErrorMessage, isNull);
      expect(profileRepository.updateCount, 0);

      await cubit.close();
    });

    test('sets recommendation fallback when selected skillsets are empty', () async {
      final cubit = _buildCubit();

      await cubit.loadRecommendation();

      expect(cubit.state.currentPage, OnboardV2PageStep.p1Intro);
      expect(cubit.state.recommendationStatus, OnboardV2RecommendationStatus.fallback);
      expect(cubit.state.recommendedCourse, isNull);

      await cubit.close();
    });

    test('preloads recommendation on P6 and waits before opening P7', () async {
      final listCompleter = Completer<BasePageBreak<CourseEntity>>();
      final courseRepository = _FakeCourseRepository(
        listCompleter: listCompleter,
        courseDetail: const CourseEntity(
          id: 'course_1',
          title: BaseMultiLanguage(en: 'Focus Basics'),
        ),
      );
      final cubit = _buildCubit(courseRepository: courseRepository);

      cubit.toggleSkillset(const SkillsetEntity(id: 'skill_1'));
      cubit.continueFromP4();
      cubit.continueFromP5();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentPage, OnboardV2PageStep.p6Notification);
      expect(cubit.state.recommendationStatus, OnboardV2RecommendationStatus.loading);
      expect(courseRepository.listCount, 1);

      final navigationFuture = cubit.continueFromP6(notificationStatus: OnboardV2NotificationStatus.maybeLater);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentPage, OnboardV2PageStep.p6Notification);

      listCompleter.complete(
        BasePageBreak<CourseEntity>(
          items: const [CourseEntity(id: 'course_1')],
        ),
      );
      await navigationFuture;

      expect(cubit.state.currentPage, OnboardV2PageStep.p7Recommendation);
      expect(cubit.state.recommendationStatus, OnboardV2RecommendationStatus.loaded);
      expect(cubit.state.recommendedCourse?.id, 'course_1');
      expect(courseRepository.listCount, 1);

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

    test('skips background onboarded update when user id is missing', () async {
      final profileRepository = _FakeProfileRepository();
      final cubit = _buildCubit(
        profileRepository: profileRepository,
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.markUserOnboardedInBackground();
      await Future<void>.delayed(Duration.zero);

      expect(profileRepository.updateCount, 0);

      await cubit.close();
    });

    test('preloads skillsets after anonymous auth succeeds', () async {
      final events = <String>[];
      var hasAnonymousSession = false;
      final homeRepository = _FakeHomeRepository(
        skillsets: const [SkillsetEntity(id: 'skill_1')],
        onGetAllSkillsets: () {
          events.add('skillsets');
          expect(hasAnonymousSession, isTrue);
        },
      );
      final cubit = _buildCubit(
        homeRepository: homeRepository,
        hasActiveAnonymousSession: () => hasAnonymousSession,
        loginAnonymousSilently: (_) async {
          events.add('login');
          hasAnonymousSession = true;
          return true;
        },
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      await cubit.loadSkillsets();

      expect(events, ['login', 'skillsets']);
      expect(homeRepository.callCount, 1);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsets.single.id, 'skill_1');

      await cubit.close();
    });

    test('reloads failed skillsets after P3 auth succeeds', () async {
      final homeRepository = _FakeHomeRepository(
        failuresBeforeSuccess: 1,
        skillsets: const [SkillsetEntity(id: 'skill_1')],
      );
      final cubit = _buildCubit(
        homeRepository: homeRepository,
        hasActiveAnonymousSession: () => true,
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      await cubit.loadSkillsets();
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.failure);

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();
      await cubit.loadSkillsets();

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(homeRepository.callCount, 2);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsets.single.id, 'skill_1');

      await cubit.close();
    });

    test('pending P1 skillset preload cannot update state after reset', () async {
      final loginCompleter = Completer<bool>();
      final homeRepository = _FakeHomeRepository(skillsets: const [SkillsetEntity(id: 'skill_1')]);
      final cubit = _buildCubit(
        homeRepository: homeRepository,
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) => loginCompleter.future,
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      final preloadFuture = cubit.loadSkillsets();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.loading);

      cubit.reset();
      loginCompleter.complete(true);
      await preloadFuture;

      expect(cubit.state.currentPage, OnboardV2PageStep.p1Intro);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.initial);
      expect(homeRepository.callCount, 0);

      await cubit.close();
    });

    test('unexpected anonymous preload errors use generic skillset copy', () async {
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) async => throw StateError('secret device token'),
        readUserState: UserState.initial,
      );

      await cubit.loadSkillsets();

      expect(cubit.state.currentPage, OnboardV2PageStep.p1Intro);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.failure);
      expect(cubit.state.skillsetErrorMessage, l10n.onboarding.onboardingV2SkillsetLoadError);
      expect(cubit.state.skillsetErrorMessage, isNot(contains('secret')));

      await cubit.close();
    });
  });
}

OnboardV2Cubit _buildCubit({
  AuthBloc? authBloc,
  UserCubit? userCubit,
  IHomeRepository? homeRepository,
  IProfileRepository? profileRepository,
  ICourseRepository? courseRepository,
  bool Function()? hasActiveAnonymousSession,
  Future<bool> Function(Map<String, dynamic> payload)? loginAnonymousSilently,
  UserState Function()? readUserState,
}) {
  return OnboardV2Cubit.withRandom(
    GetAllOnboardsUseCase(
      _FakeOnboardRepository(
        const OnboardEntity(
          age: [
            OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')),
          ],
        ),
      ),
    ),
    GetAllSkillsetsUseCase(homeRepository ?? _FakeHomeRepository()),
    UpdateUserUseCase(profileRepository ?? _FakeProfileRepository()),
    GetAllCoursesUseCase(courseRepository ?? _FakeCourseRepository()),
    GetCourseUseCase(courseRepository ?? _FakeCourseRepository()),
    _FakeDeviceInfoService(),
    authBloc ?? _MockAuthBloc(),
    userCubit ?? _MockUserCubit(),
    AppDI.injector.get<LocaleCubit>(),
    Random(0),
    hasActiveAnonymousSession: hasActiveAnonymousSession,
    loginAnonymousSilently: loginAnonymousSilently,
    readUserState: readUserState,
  );
}
