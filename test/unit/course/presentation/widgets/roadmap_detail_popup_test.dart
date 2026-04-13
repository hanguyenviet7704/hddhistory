import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

import '../../../../support/test_di.dart';

void main() {
  setUp(() async {
    await setupLocaleCubitForTests();
  });

  tearDown(() async {
    await resetInjectorForTests();
  });

  group('RoadmapDetailPopup', () {
    testWidgets('shows read and listen actions when the keypoint has usable audio', (tester) async {
      LocaleSettings.setLocaleSync(AppLocale.en);

      await tester.pumpWidget(
        _buildPopup(
          lesson: _buildLesson(
            audioUrl: const BaseMultiLanguage(en: 'https://audio.example/track.mp3'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
    });

    testWidgets('shows only read action when the keypoint has no usable audio', (tester) async {
      await LocaleSettings.setLocale(AppLocale.en);

      await tester.pumpWidget(
        _buildPopup(
          lesson: _buildLesson(),
        ),
      );
      await tester.pump();

      expect(find.text('Read'), findsOneWidget);
      expect(find.text('Listen'), findsNothing);
    });
  });
}

Widget _buildPopup({
  required LessonEntity lesson,
}) {
  return ScreenUtilInit(
    designSize: const Size(375, 812),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) => TranslationProvider(
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    ),
    child: RoadmapDetailPopup(
      lesson: lesson,
      courseLevel: CourseLevel.level1,
    ),
  );
}

LessonEntity _buildLesson({
  BaseMultiLanguage? audioUrl,
}) {
  return LessonEntity(
    id: 'lesson-1',
    title: const BaseMultiLanguage(en: 'Warm up'),
    description: const BaseMultiLanguage(en: 'Lesson description'),
    keypoints: [
      KeypointEntity(
        id: 'keypoint-1',
        title: const BaseMultiLanguage(en: 'Keypoint title'),
        description: const BaseMultiLanguage(en: 'Keypoint description'),
        estimateCompleTime: const BaseMultiLanguage(en: '2 min'),
        audio: audioUrl == null ? null : KeypointAudioEntity(url: audioUrl),
      ),
    ],
  );
}
