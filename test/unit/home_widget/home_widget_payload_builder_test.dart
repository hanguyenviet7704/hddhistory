import 'package:flutter_test/flutter_test.dart';
import 'package:meup/meup.dart';

void main() {
  final updatedAt = DateTime.utc(2026, 6, 9);

  group('HomeWidgetPayloadBuilder', () {
    test('builds ready in-progress payload with locale fallback and clamped progress', () {
      final payload = HomeWidgetPayloadBuilder.buildInProgress(
        HomeWidgetCourseEntity(
          courseId: 'course-1',
          title: const BaseMultiLanguage(vi: '', en: 'Habit formation'),
          image: 'https://cdn.example.com/course.jpg',
          completedLesson: 7,
          totalLesson: 6,
        ),
        localeCode: 'vi',
        updatedAt: updatedAt,
      );

      expect(payload.widgetType, HomeWidgetType.inProgressCourse);
      expect(payload.state, HomeWidgetPayloadState.ready);
      expect(payload.storageKey, HomeWidgetStorageKeys.inProgressPayload);
      expect(payload.imageUrl, 'https://cdn.example.com/course.jpg');
      expect(payload.data['title'], 'Habit formation');
      expect(payload.data['completedLessons'], 7);
      expect(payload.data['totalLessons'], 6);
      expect(payload.data['progress'], 1);
      expect(payload.deeplink, 'meup://course-roadmap?courseId=course-1&source=home_widget&widgetType=in_progress_course');
    });

    test('builds empty in-progress payload when data is null or invalid', () {
      final nullPayload = HomeWidgetPayloadBuilder.buildInProgress(
        null,
        localeCode: 'en',
        updatedAt: updatedAt,
      );
      final invalidPayload = HomeWidgetPayloadBuilder.buildInProgress(
        HomeWidgetCourseEntity(
          courseId: 'course-1',
          title: const BaseMultiLanguage(en: 'Invalid'),
          image: 'https://cdn.example.com/course.jpg',
          completedLesson: 1,
          totalLesson: 0,
        ),
        localeCode: 'en',
        updatedAt: updatedAt,
      );

      for (final payload in [nullPayload, invalidPayload]) {
        expect(payload.state, HomeWidgetPayloadState.empty);
        expect(payload.imageUrl, isNull);
        expect(payload.data['title'], 'Pick a course and stay in the loop');
        expect(payload.deeplink, 'meup://home?source=home_widget&widgetType=in_progress_course&state=empty');
      }
    });

    test('builds streak payload with Monday-first week study and zero subtitle', () {
      final payload = HomeWidgetPayloadBuilder.buildStreak(
        HomeWidgetStreakEntity(
          weekStartDate: DateTime.utc(2026, 6, 2),
          weekStudy: const [true, false, true],
          studyTime: 45,
          currentStreak: 0,
          bestStreak: 10,
        ),
        updatedAt: updatedAt,
      );

      expect(payload.widgetType, HomeWidgetType.weeklyStreak);
      expect(payload.state, HomeWidgetPayloadState.ready);
      expect(payload.storageKey, HomeWidgetStorageKeys.streakPayload);
      expect(payload.staticAssetKey, HomeWidgetStorageKeys.flameAsset);
      expect(payload.data['subtitle'], 'Start your streak today');
      expect(payload.data['weekStudy'], [true, false, true, false, false, false, false]);
      expect(payload.data['weekStartDate'], '2026-06-02');
      expect(payload.deeplink, 'meup://course-roadmap?source=home_widget&widgetType=weekly_streak');
    });

    test('builds suggest ready and exhausted payloads', () {
      final ready = HomeWidgetPayloadBuilder.buildSuggestCourse(
        HomeWidgetCourseEntity(
          courseId: 'course-2',
          title: const BaseMultiLanguage(vi: '', en: 'Suggested course'),
          description: const BaseMultiLanguage(vi: '', en: 'Try this next'),
          image: 'https://cdn.example.com/suggest.jpg',
        ),
        localeCode: 'vi',
        updatedAt: updatedAt,
        suggestionDate: DateTime.utc(2026, 6, 9),
      );
      final exhausted = HomeWidgetPayloadBuilder.buildSuggestCourse(
        null,
        localeCode: 'en',
        updatedAt: updatedAt,
        suggestionDate: DateTime.utc(2026, 6, 9),
      );

      expect(ready.state, HomeWidgetPayloadState.ready);
      expect(ready.storageKey, HomeWidgetStorageKeys.suggestCoursePayload);
      expect(ready.imageKey, HomeWidgetStorageKeys.suggestCourseImage);
      expect(ready.data['localeCode'], 'vi');
      expect(ready.data['title'], 'Suggested course');
      expect(ready.data['description'], 'Try this next');
      expect(ready.data['suggestionDate'], '2026-06-09');
      expect(ready.deeplink, 'meup://course-roadmap?courseId=course-2&source=home_widget&widgetType=suggest_course');

      expect(exhausted.state, HomeWidgetPayloadState.exhausted);
      expect(exhausted.data['title'], 'You crushed every course!');
      expect(exhausted.staticAssetKey, HomeWidgetStorageKeys.certificateAsset);
      expect(exhausted.deeplink, 'meup://home?source=home_widget&widgetType=suggest_course&state=exhausted');
    });
  });
}
