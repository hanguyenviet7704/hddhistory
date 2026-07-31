import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

class _FakeLearningStreakRepository implements ILearningStreakRepository {
  _FakeLearningStreakRepository(this.handler);

  TaskEither<AppException, LearningStreakFetchEntity> Function(String userId) handler;

  /// Overridden per test that exercises the check-in path; the default is a
  /// success carrying whatever [handler] would return, so tests that only care
  /// about the read path need not set it.
  TaskEither<AppException, UserLearningStreakEntity> Function(String userId)? checkInHandler;

  @override
  TaskEither<AppException, LearningStreakFetchEntity> getUserLearningStreak(String userId) {
    return handler(userId);
  }

  @override
  TaskEither<AppException, UserLearningStreakEntity> checkInStreak(String userId) {
    final override = checkInHandler;
    if (override != null) return override(userId);
    return handler(userId).map((fetch) => fetch.streak);
  }

  @override
  TaskEither<AppException, StreakPopupConfigEntity> getStreakPopupConfig() {
    return TaskEither.right(const StreakPopupConfigEntity());
  }
}

class _LearningStreakPageHarness {
  _LearningStreakPageHarness({
    required this.router,
    required this.userCubit,
    required this.learningStreakCubit,
    required this.mockTracking,
  });

  final GoRouter router;
  final UserCubit userCubit;
  final LearningStreakCubit learningStreakCubit;
  final MockTrackingService mockTracking;
}

Future<_LearningStreakPageHarness> _pumpHarness(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await setupLocaleCubitForTests();
  LocaleSettings.setLocaleSync(AppLocale.en);

  final mockTracking = MockTrackingService();
  AppDI.injector.registerSingleton<ITrackingService>(
    AppTrackingService(mockTracking),
  );

  final userCubit = UserCubit(mockTracking);
  AppDI.injector.registerSingleton<UserCubit>(userCubit);
  final repo = _FakeLearningStreakRepository(
    (_) => TaskEither.right(
      const LearningStreakFetchEntity(
        streak: UserLearningStreakEntity(currentStreak: 3),
        origin: LearningStreakDataOrigin.remote,
      ),
    ),
  );
  final learningStreakCubit = LearningStreakCubit(
    GetUserLearningStreakUseCase(repo),
    CheckInStreakUseCase(repo),
  );
  AppDI.injector.registerSingleton<LearningStreakCubit>(learningStreakCubit);

  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(body: SizedBox.shrink()),
      ),
      GoRoute(
        path: '/streak',
        builder: (context, state) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<UserCubit>.value(value: userCubit),
              BlocProvider<LearningStreakCubit>.value(value: learningStreakCubit),
            ],
            child: const LearningStreakPage(),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    ),
  );

  router.push('/streak');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));

  return _LearningStreakPageHarness(
    router: router,
    userCubit: userCubit,
    learningStreakCubit: learningStreakCubit,
    mockTracking: mockTracking,
  );
}

int _countTrackedEvent(MockTrackingService tracking, String eventName) {
  return tracking.events.where((event) => event.name == eventName).length;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    if (AppDI.injector.isRegistered<LearningStreakCubit>()) {
      await AppDI.injector.get<LearningStreakCubit>().close();
    }
    if (AppDI.injector.isRegistered<UserCubit>()) {
      await AppDI.injector.get<UserCubit>().close();
    }
    if (AppDI.injector.isRegistered<LocaleCubit>()) {
      await AppDI.injector.get<LocaleCubit>().close();
    }
    await AppDI.injector.reset();
  });

  testWidgets('tracks popup view and close exactly once when close button is tapped', (tester) async {
    final harness = await _pumpHarness(tester);

    await tester.tap(find.byKey(const ValueKey('learningStreakPopupCloseButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupView), 1);
    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupClose), 1);
  });

  testWidgets('tracks popup view and close exactly once when scrim is tapped', (tester) async {
    final harness = await _pumpHarness(tester);

    await tester.tapAt(const Offset(12, 12));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupView), 1);
    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupClose), 1);
  });

  testWidgets('tracks popup view and close exactly once on system back', (tester) async {
    final harness = await _pumpHarness(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));

    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupView), 1);
    expect(_countTrackedEvent(harness.mockTracking, TrackingKey.homeStreakPopupClose), 1);
  });
}
