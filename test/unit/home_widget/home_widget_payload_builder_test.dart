import 'package:flutter_test/flutter_test.dart';
import 'package:hddhistory/hddhistory.dart';

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
      expect(payload.deeplink, 'hddhistory://course-roadmap?courseId=course-1&source=home_widget&widgetType=in_progress_course');
    });

    test('builds empty in-progress payload when data is null or invalid', () {
      const textDefaults = HomeWidgetTextDefaults(
        inProgressEmptyTitle: 'Chọn khóa học để bắt đầu',
      );
      final nullPayload = HomeWidgetPayloadBuilder.buildInProgress(
        null,
        localeCode: 'en',
        updatedAt: updatedAt,
        textDefaults: textDefaults,
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
        textDefaults: textDefaults,
      );

      for (final payload in [nullPayload, invalidPayload]) {
        expect(payload.state, HomeWidgetPayloadState.empty);
        expect(payload.imageUrl, isNull);
        expect(payload.data['title'], 'Chọn khóa học để bắt đầu');
        expect(payload.deeplink, 'hddhistory://home?source=home_widget&widgetType=in_progress_course&state=empty');
      }
    });

    test('builds streak payload with Monday-first week study and zero subtitle', () {
      const textDefaults = HomeWidgetTextDefaults(
        streakEmptySubtitle: 'Bắt đầu chuỗi hôm nay',
        weekLabels: ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
        streakCountSingularTemplate: '{count} ngày',
        streakCountPluralTemplate: '{count} ngày',
      );
      final payload = HomeWidgetPayloadBuilder.buildStreak(
        HomeWidgetStreakEntity(
          weekStartDate: DateTime.utc(2026, 6, 2),
          weekStudy: const [true, false, true],
          studyTime: 45,
          currentStreak: 0,
          bestStreak: 10,
        ),
        localeCode: 'vi',
        updatedAt: updatedAt,
        textDefaults: textDefaults,
      );

      expect(payload.widgetType, HomeWidgetType.weeklyStreak);
      expect(payload.state, HomeWidgetPayloadState.ready);
      expect(payload.storageKey, HomeWidgetStorageKeys.streakPayload);
      expect(payload.staticAssetKey, HomeWidgetStorageKeys.flameAsset);
      expect(payload.data['localeCode'], 'vi');
      expect(payload.data['subtitle'], 'Bắt đầu chuỗi hôm nay');
      expect(payload.data['countText'], '0 ngày');
      expect(payload.data['weekLabels'], ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']);
      expect(payload.data['weekStudy'], [true, false, true, false, false, false, false]);
      expect(payload.data['weekStartDate'], '2026-06-02');
      expect(payload.deeplink, 'hddhistory://course-roadmap?source=home_widget&widgetType=weekly_streak');
    });

    test('builds suggest ready and exhausted payloads', () {
      const textDefaults = HomeWidgetTextDefaults(
        suggestLabel: 'Gợi ý hôm nay',
        suggestExhaustedTitle: 'Bạn đã hoàn thành mọi khóa học!',
        suggestExhaustedSubtitle: 'Sắp có thêm!',
      );
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
        textDefaults: textDefaults,
      );
      final exhausted = HomeWidgetPayloadBuilder.buildSuggestCourse(
        null,
        localeCode: 'en',
        updatedAt: updatedAt,
        suggestionDate: DateTime.utc(2026, 6, 9),
        textDefaults: textDefaults,
      );

      expect(ready.state, HomeWidgetPayloadState.ready);
      expect(ready.storageKey, HomeWidgetStorageKeys.suggestCoursePayload);
      expect(ready.imageKey, HomeWidgetStorageKeys.suggestCourseImage);
      expect(ready.data['localeCode'], 'vi');
      expect(ready.data['label'], 'Gợi ý hôm nay');
      expect(ready.data['title'], 'Suggested course');
      expect(ready.data['description'], 'Try this next');
      expect(ready.data['suggestionDate'], '2026-06-09');
      expect(ready.deeplink, 'hddhistory://course-roadmap?courseId=course-2&source=home_widget&widgetType=suggest_course');

      expect(exhausted.state, HomeWidgetPayloadState.exhausted);
      expect(exhausted.data['title'], 'Bạn đã hoàn thành mọi khóa học!');
      expect(exhausted.data['subtitle'], 'Sắp có thêm!');
      expect(exhausted.staticAssetKey, HomeWidgetStorageKeys.certificateAsset);
      expect(exhausted.deeplink, 'hddhistory://home?source=home_widget&widgetType=suggest_course&state=exhausted');
    });

    test('loads widget default text for locale code', () async {
      final defaults = await HomeWidgetTextDefaults.load('vi');

      expect(defaults.inProgressEmptyTitle, 'Chọn khóa học để bắt đầu');
      expect(defaults.suggestLabel, 'Gợi ý hôm nay');
      expect(defaults.progressText(completed: 1, total: 5), '1/5 bài học');
      expect(defaults.streakCountText(2), '2 ngày');
      expect(defaults.weekLabels, ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN']);
    });

    test('preserves changed course id when applying text defaults to sync params', () {
      final params = HomeWidgetSyncParams(
        localeCode: 'en',
        now: updatedAt,
        changedCourseId: 'course-1',
      );

      final localized = params.withTextDefaults(const HomeWidgetTextDefaults());

      expect(localized.changedCourseId, 'course-1');
      expect(localized.localDateKey, '2026-06-09');
    });
  });
}
