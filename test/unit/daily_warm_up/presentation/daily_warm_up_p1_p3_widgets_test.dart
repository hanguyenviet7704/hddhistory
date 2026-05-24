import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('Daily warm-up P1/P3 widgets', () {
    testWidgets('P1 renders entry copy and handles actions without overflow', (tester) async {
      var started = false;
      var dismissed = false;
      await tester.binding.setSurfaceSize(const Size(375, 640));
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
      expect(started, isTrue);
      expect(dismissed, isTrue);
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
      expect(find.byType(DailyWarmUpCourseCard, skipOffstage: false), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(explored, isTrue);
      expect(startTapped, isFalse);
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
