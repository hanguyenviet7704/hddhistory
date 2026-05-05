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
  Map<String, dynamic>? lastParams;
  int updateCount = 0;

  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity(id: 'user_1'));

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) {
    lastParams = params;
    updateCount += 1;
    return TaskEither.right(UserEntity(id: params['id'] as String? ?? ''));
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
    test('initialize loads onboarding copy without requesting token-gated skillsets', () async {
      final homeRepository = _FakeHomeRepository(
        skillsets: const [SkillsetEntity(id: 'skill_1')],
      );
      final cubit = _buildCubit(homeRepository: homeRepository);

      await cubit.initialize();

      expect(cubit.state.onboardStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.initial);
      expect(homeRepository.callCount, 0);

      await cubit.close();
    });

    test('accepts existing anonymous session but still updates user profile before P4', () async {
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

      expect(loginCount, 0);
      expect(profileRepository.updateCount, 1);
      expect(profileRepository.lastParams, containsPair('id', 'user_1'));
      expect(profileRepository.lastParams, containsPair('name', 'Alice'));
      expect(profileRepository.lastParams, containsPair('age', '18-24'));
      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.success);

      await cubit.close();
    });

    test('stays on P3 when anonymous login fails', () async {
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) async => false,
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(cubit.state.currentPage, OnboardV2PageStep.p3Age);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.failure);
      expect(cubit.state.p3ErrorMessage, isNotEmpty);

      await cubit.close();
    });

    test('stays on P3 when current user id is missing after session acceptance', () async {
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => true,
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(cubit.state.currentPage, OnboardV2PageStep.p3Age);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.failure);
      expect(cubit.state.p3ErrorMessage, contains('user'));

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

    test('loads skillsets only after P3 anonymous auth and profile update succeeds', () async {
      final events = <String>[];
      var anonymousSessionReady = false;
      final homeRepository = _FakeHomeRepository(
        skillsets: const [SkillsetEntity(id: 'skill_1')],
        onGetAllSkillsets: () {
          events.add('skillsets');
          expect(anonymousSessionReady, isTrue);
        },
      );
      final cubit = _buildCubit(
        homeRepository: homeRepository,
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) async {
          events.add('login');
          anonymousSessionReady = true;
          return true;
        },
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(events, ['login', 'skillsets']);
      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(homeRepository.callCount, 1);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsets.single.id, 'skill_1');

      await cubit.close();
    });

    test('reloads failed skillsets after P3 auth and profile update succeeds', () async {
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
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.currentPage, OnboardV2PageStep.p4Skillset);
      expect(homeRepository.callCount, 2);
      expect(cubit.state.skillsetStatus, OnboardV2AsyncStatus.success);
      expect(cubit.state.skillsets.single.id, 'skill_1');

      await cubit.close();
    });

    test('pending P3 submit cannot advance after user backs up', () async {
      final loginCompleter = Completer<bool>();
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) => loginCompleter.future,
        readUserState: () => const UserState(
          auth: AuthEntity(user: UserEntity(id: 'user_1', anonymous: true)),
        ),
      );

      cubit.continueFromIntro();
      cubit.updateName('Alice');
      cubit.continueFromName();
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));

      final submitFuture = cubit.submitAge();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.loading);

      cubit.goBack();
      loginCompleter.complete(true);
      await submitFuture;

      expect(cubit.state.currentPage, OnboardV2PageStep.p2Name);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.initial);

      await cubit.close();
    });

    test('unexpected P3 submit errors use generic localized copy', () async {
      final cubit = _buildCubit(
        hasActiveAnonymousSession: () => false,
        loginAnonymousSilently: (_) => throw StateError('secret device token'),
        readUserState: UserState.initial,
      );

      cubit.updateName('Alice');
      cubit.selectAge(const OnboardOptionEntity(id: 1, label: BaseMultiLanguage(en: '18-24')));
      await cubit.submitAge();

      expect(cubit.state.currentPage, OnboardV2PageStep.p3Age);
      expect(cubit.state.p3SubmitStatus, OnboardV2AsyncStatus.failure);
      expect(cubit.state.p3ErrorMessage, l10n.onboarding.onboardingV2GenericError);
      expect(cubit.state.p3ErrorMessage, isNot(contains('secret')));

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
