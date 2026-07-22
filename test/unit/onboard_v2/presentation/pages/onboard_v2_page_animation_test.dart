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

class _FakeOnboardingRepository implements IOnboardingRepository {
  @override
  TaskEither<AppException, OnboardingContentConfigEntity> getOnboardingConfig() => TaskEither.right(const OnboardingContentConfigEntity());
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

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.withRandom(
        GetOnboardingContentConfigUseCase(_FakeOnboardingRepository()),
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

  testWidgets('progress header stays anchored while step pages swipe', (tester) async {
    final cubit = _SeededOnboardV2Cubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(BlocProvider<OnboardV2Cubit>.value(value: cubit, child: const OnboardV2Page())));

    cubit.continueFromIntro();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 380));

    final p2HeaderFinder = find.byKey(const ValueKey('onboard_v2_progress_header_1'), skipOffstage: false);
    expect(p2HeaderFinder, findsOneWidget);
    final anchoredLeft = tester.getTopLeft(p2HeaderFinder).dx;

    cubit.updateName('Ava');
    cubit.continueFromName();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 170));

    final p3HeaderFinder = find.byKey(const ValueKey('onboard_v2_progress_header_2'), skipOffstage: false);
    expect(p3HeaderFinder, findsOneWidget);
    final p2DuringLeft = tester.getTopLeft(p2HeaderFinder).dx;
    final p3DuringLeft = tester.getTopLeft(p3HeaderFinder).dx;
    final animatingPageView = tester.widget<PageView>(find.byKey(const Key('onboard_v2_step_page_view')));
    expect((p2DuringLeft - anchoredLeft).abs(), lessThan(1));
    expect((p3DuringLeft - anchoredLeft).abs(), lessThan(1));

    expect(animatingPageView.controller?.page, greaterThan(1));
    expect(animatingPageView.controller?.page, lessThan(2));

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('P5 path subtitle reflects selected option count', (tester) async {
    final cubit = _SeededOnboardV2Cubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(_buildHarness(BlocProvider<OnboardV2Cubit>.value(value: cubit, child: const OnboardV2PathSelectionPage())));

    expect(find.text('Pick up 0/2 you most want to grow in'), findsOneWidget);

    cubit.togglePath(OnboardingPath.feelBetter);
    await tester.pump();
    expect(find.text('Pick up 1/2 you most want to grow in'), findsOneWidget);

    cubit.togglePath(OnboardingPath.thinkBetter);
    await tester.pump();
    expect(find.text('Pick up 2/2 you most want to grow in'), findsOneWidget);

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
