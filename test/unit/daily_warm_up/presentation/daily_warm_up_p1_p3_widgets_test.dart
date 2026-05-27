import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lottie/lottie.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';
import 'daily_warm_up_test_fakes.dart';

void main() {
  setUpAll(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  setUp(() {
    if (!AppDI.injector.isRegistered<ITrackingService>()) {
      AppDI.injector.registerSingleton<ITrackingService>(
        AppTrackingService(NoOpTrackingService()),
      );
    }
  });

  tearDownAll(() async {
    await resetInjectorForTests();
  });

  group('Daily warm-up P1/P3 widgets', () {
    testWidgets('P1 renders centered entry CTA and handles actions without overflow', (tester) async {
      var started = false;
      var dismissed = false;
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpEntryStep(
            onStart: () => started = true,
            onMaybeLater: () => dismissed = true,
          ),
        ),
      );

      await tester.tap(find.text('Start warm-up'));
      await tester.pump();
      await tester.tap(find.text('Maybe later'));
      await tester.pump();

      expect(find.text('Daily challenge'), findsOneWidget);
      expect(tester.getSize(find.byType(ElevatedButton)).width, lessThan(280));
      expect(started, isTrue);
      expect(dismissed, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P1 avoids overflow on a small Android viewport', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpEntryStep(
            onStart: () {},
            onMaybeLater: () {},
          ),
        ),
      );

      expect(find.text('Daily challenge'), findsOneWidget);
      expect(find.text('Start warm-up'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('DailyWarmUpPage marks shown date when route opens with initial entry state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final localDataSource = FakeDailyWarmUpLocalDataSource()..onboardingCompletedDates['user-1'] = '2026-05-21';
      final cubit = DailyWarmUpCubit(
        GetDailyWarmUpUseCase(FakeDailyWarmUpRepository(TaskEither.right(dailyWarmUpTestEntity()))),
        localDataSource,
        GetCourseUseCase(FakeCourseRepository()),
      );
      addTearDown(cubit.close);

      final canOpen = await cubit.loadForHomeEntry(
        userId: 'user-1',
        localDate: '2026-05-22',
        hasCompletedOnboarding: true,
      );

      await tester.pumpWidget(
        _harness(
          BlocProvider.value(
            value: cubit,
            child: const DailyWarmUpPage(),
          ),
        ),
      );
      await tester.pump();

      expect(canOpen, isTrue);
      expect(find.text('Daily challenge'), findsOneWidget);
      expect(localDataSource.shownDates['user-1'], '2026-05-22');
      expect(cubit.state.hasMarkedShown, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P3 renders suggested course and disables primary CTA while routing', (tester) async {
      var explored = false;
      var startTapped = false;
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          DailyWarmUpCompletionStep(
            state: DailyWarmUpState(
              status: DailyWarmUpStatus.completion,
              entity: const DailyWarmUpEntity(isKeypointCompleted: false, suggestedCourseId: 'course-2'),
              suggestedCourse: CourseEntity(id: 'course-2', title: _text('Mindful Speaking')),
              isRoutingToRoadmap: true,
            ),
            onStartLesson: () => startTapped = true,
            onExploreMore: () => explored = true,
          ),
        ),
      );

      await tester.tap(find.text('Explore more'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Complete challenge!'), findsOneWidget);
      final courseCardFinder = find.byType(DailyWarmUpCourseCard, skipOffstage: false);
      expect(courseCardFinder, findsOneWidget);
      expect(find.byType(LottieBuilder), findsOneWidget);
      expect(tester.getSize(courseCardFinder).width, greaterThan(280));
      expect(tester.getSize(courseCardFinder).width, lessThanOrEqualTo(307));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(explored, isTrue);
      expect(startTapped, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('P3 hides Lottie background when accessibility animations are disabled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 812));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _harness(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(375, 812),
              disableAnimations: true,
              accessibleNavigation: true,
            ),
            child: DailyWarmUpCompletionStep(
              state: DailyWarmUpState(
                status: DailyWarmUpStatus.completion,
                entity: const DailyWarmUpEntity(isKeypointCompleted: true, suggestedCourseId: 'course-2'),
                suggestedCourse: CourseEntity(id: 'course-2', title: _text('Mindful Speaking')),
              ),
              onStartLesson: () {},
              onExploreMore: () {},
            ),
          ),
        ),
      );

      expect(find.byType(LottieBuilder), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}

Widget _harness(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, _) => TranslationProvider(
      child: MaterialApp(home: child),
    ),
  );
}

BaseMultiLanguage _text(String value) => BaseMultiLanguage(en: value, vi: value, zh: value);
