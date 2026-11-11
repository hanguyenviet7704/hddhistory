import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hddhistory/hddhistory.dart';
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

  @override
  TaskEither<AppException, OnboardingTaxonomyEntity> getTaxonomy() => TaskEither.right(const OnboardingTaxonomyEntity());

  @override
  TaskEither<AppException, OnboardingRecommendationEntity> submitAnswers(OnboardingAnswersRequest request) =>
      TaskEither.right(const OnboardingRecommendationEntity());
}

class _FakeProfileRepository implements IProfileRepository {
  @override
  TaskEither<AppException, UserEntity> getUser(String id) => TaskEither.right(const UserEntity());

  @override
  TaskEither<AppException, UserEntity> updateUser(Map<String, dynamic> params) => TaskEither.right(const UserEntity());
}

class _SeededOnboardV2Cubit extends OnboardV2Cubit {
  _SeededOnboardV2Cubit()
    : super.forTest(
        GetOnboardingContentConfigUseCase(_FakeOnboardingRepository()),
        UpdateUserUseCase(_FakeProfileRepository()),
        GetOnboardingTaxonomyUseCase(_FakeOnboardingRepository()),
        SubmitOnboardingAnswersUseCase(_FakeOnboardingRepository()),
        _FakeDeviceInfoService(),
        _MockAuthBloc(),
        _MockUserCubit(),
        AppDI.injector.get<LocaleCubit>(),
      );
}

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.vi);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  testWidgets('P1 renders animated carousel surface', (tester) async {
    final cubit = _SeededOnboardV2Cubit();
    addTearDown(cubit.close);

    await tester.pumpWidget(
      _buildHarness(BlocProvider<OnboardV2Cubit>.value(value: cubit, child: const OnboardV2IntroCarousel())),
    );

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

    // P2Name schedules a 400ms delayed focus request from initState (keeps
    // the keyboard from raising mid P1→P2 transition) — flush it before the
    // widget tree is torn down, or the pending-timer teardown check fails.
    await tester.pump(const Duration(milliseconds: 400));
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

    // P2Name only enters the PageView's build range partway through the
    // P1→P2 swipe and then schedules its own 400ms delayed focus timer —
    // flush it before teardown or the pending-timer check fails.
    await tester.pump(const Duration(milliseconds: 800));
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
