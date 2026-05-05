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
  Future<BaseDeviceInfo?> get deviceInfo async => null;

  @override
  Future<String> get deviceName async => 'iPhone';

  @override
  Future<String> get deviceToken async => 'device-token';

  @override
  Future<void> getAllDeviceInfo() async {}

  @override
  Future<int?> getAndroidSdkVersion() async => null;

  @override
  Future<bool> isAndroid13OrHigher() async => false;
}

class _FakeOnboardRepository implements IOnboardRepository {
  @override
  TaskEither<AppException, OnboardEntity> getAllOnboards() => TaskEither.right(const OnboardEntity());

  @override
  TaskEither<AppException, UserEntity> getUserByDeviceId(String deviceId) => TaskEither.right(const UserEntity());
}

class _FakeHomeRepository implements IHomeRepository {
  @override
  TaskEither<AppException, BasePageBreak<SkillsetEntity>> getAllSkillsets(PageBreakRequest<SkillsetFilterRequest> request) {
    return TaskEither.right(BasePageBreak<SkillsetEntity>());
  }

  @override
  TaskEither<AppException, SkillsetEntity> getSkillset(String id) => TaskEither.right(const SkillsetEntity());
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity());

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) => TaskEither.right(const UserEntity());
}

class _FakeCourseRepository implements ICourseRepository {
  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getAllCourses(PageBreakRequest<CourseFilterRequest> request) {
    return TaskEither.right(BasePageBreak<CourseEntity>());
  }

  @override
  TaskEither<AppException, CourseEntity> getCourse(String id) => TaskEither.left(const AppException.notFound('missing course'));

  @override
  TaskEither<AppException, RoadmapEntity> getRoadmap(String id) => TaskEither.right(const RoadmapEntity());
}

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.withRandom(
        GetAllOnboardsUseCase(_FakeOnboardRepository()),
        GetAllSkillsetsUseCase(_FakeHomeRepository()),
        UpdateUserUseCase(_FakeProfileRepository()),
        GetAllCoursesUseCase(_FakeCourseRepository()),
        GetCourseUseCase(_FakeCourseRepository()),
        _FakeDeviceInfoService(),
        _MockAuthBloc(),
        _MockUserCubit(),
        AppDI.injector.get<LocaleCubit>(),
        Random(0),
      );
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('P1 renders animated carousel surface', (tester) async {
    await tester.pumpWidget(_buildHarness(const OnboardV2IntroCarousel()));

    expect(find.byKey(const Key('onboard_v2_intro_carousel')), findsOneWidget);
    expect(find.byKey(const Key('onboard_v2_intro_carousel_animation')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3000));
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Onboard V2 step changes animate through the page view', (tester) async {
    final cubit = _SeededOnboardV2Cubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(BlocProvider<OnboardV2Cubit>.value(value: cubit, child: const OnboardV2Page())));
    expect(find.byKey(const Key('onboard_v2_step_page_view')), findsOneWidget);

    final initialPageView = tester.widget<PageView>(find.byKey(const Key('onboard_v2_step_page_view')));
    expect(initialPageView.physics, isA<NeverScrollableScrollPhysics>());
    expect(initialPageView.controller?.page, 0);

    cubit.continueFromIntro();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));

    final animatingPageView = tester.widget<PageView>(find.byKey(const Key('onboard_v2_step_page_view')));
    expect(animatingPageView.controller?.page, greaterThan(0));
    expect(animatingPageView.controller?.page, lessThan(1));

    await tester.pump(const Duration(milliseconds: 220));
    expect(animatingPageView.controller?.page?.round(), 1);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

Widget _buildHarness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(home: child),
    ),
  );
}
