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

  testWidgets('tracks popup view and close when dismissed without starting', (tester) async {
    final trackingBase = MockTrackingService();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(trackingBase));

    await tester.pumpWidget(
      _buildTestShell(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              VideoLessonIntroSheet.show(
                context,
                lesson: _lesson(),
                nodeId: 'node-1',
                trackingData: _trackingData(),
                onStart: () {},
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonPopupView), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonPopupClose), isFalse);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonStartClick), isFalse);

    await tester.tapAt(const Offset(8, 8));
    await tester.pumpAndSettle();

    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonPopupClose), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonStartClick), isFalse);
  });

  testWidgets('tracks start click and runs the start callback', (tester) async {
    final trackingBase = MockTrackingService();
    AppDI.injector.registerSingleton<ITrackingService>(AppTrackingService(trackingBase));

    var startCount = 0;
    await tester.pumpWidget(
      _buildTestShell(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              VideoLessonIntroSheet.show(
                context,
                lesson: _lesson(),
                nodeId: 'node-1',
                trackingData: _trackingData(),
                onStart: () => startCount += 1,
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start watching'));
    await tester.pumpAndSettle();

    expect(startCount, 1);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonPopupView), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonStartClick), isTrue);
    expect(trackingBase.hasTrackedEvent(TrackingKey.videoLessonPopupClose), isFalse);
  });
}

Widget _buildTestShell({required Widget child}) {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(body: child),
      ),
    ],
  );

  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, widget) => TranslationProvider(
      child: MaterialApp.router(routerConfig: router),
    ),
    child: child,
  );
}

CourseLessonTrackingData _trackingData() => CourseLessonTrackingData(
  skillset: const SkillsetEntity(
    id: 'skill-1',
    title: BaseMultiLanguage(en: 'Listening'),
  ),
  course: const CourseEntity(
    id: 'course-1',
    title: BaseMultiLanguage(en: 'English'),
    skillsetId: 'skill-1',
  ),
  lesson: _lesson(),
);

LessonEntity _lesson() => const LessonEntity(
  id: 'lesson-1',
  courseId: 'course-1',
  type: LessonType.video,
  title: BaseMultiLanguage(en: 'Intro video'),
  description: BaseMultiLanguage(en: 'Learn the basics before you start.'),
  estimateCompleTime: BaseMultiLanguage(en: '5 min'),
);
