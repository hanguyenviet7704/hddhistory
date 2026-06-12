part of '../../home_widget.dart';

class HomeWidgetPayloadBuilder {
  static HomeWidgetPayload buildInProgress(
    HomeWidgetCourseEntity? course, {
    required String localeCode,
    required DateTime updatedAt,
  }) {
    if (course == null || course.courseId.isEmpty || course.totalLesson <= 0) {
      return HomeWidgetPayload(
        widgetType: HomeWidgetType.inProgressCourse,
        state: HomeWidgetPayloadState.empty,
        updatedAt: updatedAt,
        deeplink: 'meup://home?source=home_widget&widgetType=${HomeWidgetType.inProgressCourse.value}&state=${HomeWidgetPayloadState.empty.value}',
        staticAssetKey: HomeWidgetStorageKeys.bookAsset,
        data: {
          'localeCode': localeCode,
          'title': 'Pick a course and stay in the loop',
          'staticAssetKey': HomeWidgetStorageKeys.bookAsset,
        },
      );
    }

    final progress = (course.completedLesson / course.totalLesson).clamp(0.0, 1.0);
    return HomeWidgetPayload(
      widgetType: HomeWidgetType.inProgressCourse,
      state: HomeWidgetPayloadState.ready,
      updatedAt: updatedAt,
      deeplink: 'meup://course-roadmap?courseId=${Uri.encodeQueryComponent(course.courseId)}&source=home_widget&widgetType=${HomeWidgetType.inProgressCourse.value}',
      imageUrl: course.image.isEmpty ? null : course.image,
      data: {
        'courseId': course.courseId,
        'localeCode': localeCode,
        'title': _localizedText(course.title, localeCode),
        'imagePathKey': HomeWidgetStorageKeys.inProgressImage,
        'completedLessons': course.completedLesson,
        'totalLessons': course.totalLesson,
        'progress': progress,
      },
    );
  }

  static HomeWidgetPayload buildStreak(
    HomeWidgetStreakEntity streak, {
    required DateTime updatedAt,
  }) {
    final weekStudy = List<bool>.from(streak.weekStudy.take(7));
    while (weekStudy.length < 7) {
      weekStudy.add(false);
    }

    return HomeWidgetPayload(
      widgetType: HomeWidgetType.weeklyStreak,
      state: HomeWidgetPayloadState.ready,
      updatedAt: updatedAt,
      deeplink: 'meup://course-roadmap?source=home_widget&widgetType=${HomeWidgetType.weeklyStreak.value}',
      staticAssetKey: HomeWidgetStorageKeys.flameAsset,
      data: {
        'currentStreak': streak.currentStreak,
        'subtitle': streak.currentStreak > 0 ? 'Keep going!' : 'Start your streak today',
        'weekStudy': weekStudy,
        'weekStartDate': _dateOnly(streak.weekStartDate ?? updatedAt),
        'studyTime': streak.studyTime,
        'bestStreak': streak.bestStreak,
        'staticAssetKey': HomeWidgetStorageKeys.flameAsset,
      },
    );
  }

  static HomeWidgetPayload buildSuggestCourse(
    HomeWidgetCourseEntity? course, {
    required String localeCode,
    required DateTime updatedAt,
    required DateTime suggestionDate,
  }) {
    if (course == null || course.courseId.isEmpty) {
      return HomeWidgetPayload(
        widgetType: HomeWidgetType.suggestCourse,
        state: HomeWidgetPayloadState.exhausted,
        updatedAt: updatedAt,
        deeplink: 'meup://home?source=home_widget&widgetType=${HomeWidgetType.suggestCourse.value}&state=${HomeWidgetPayloadState.exhausted.value}',
        staticAssetKey: HomeWidgetStorageKeys.certificateAsset,
        data: {
          'localeCode': localeCode,
          'title': 'You crushed every course!',
          'subtitle': 'More coming soon!',
          'staticAssetKey': HomeWidgetStorageKeys.certificateAsset,
        },
      );
    }

    return HomeWidgetPayload(
      widgetType: HomeWidgetType.suggestCourse,
      state: HomeWidgetPayloadState.ready,
      updatedAt: updatedAt,
      deeplink: 'meup://course-roadmap?courseId=${Uri.encodeQueryComponent(course.courseId)}&source=home_widget&widgetType=${HomeWidgetType.suggestCourse.value}',
      imageUrl: course.image.isEmpty ? null : course.image,
      data: {
        'courseId': course.courseId,
        'localeCode': localeCode,
        'label': "Today's suggestion",
        'title': _localizedText(course.title, localeCode),
        'description': _localizedText(course.description, localeCode),
        'imagePathKey': HomeWidgetStorageKeys.suggestCourseImage,
        'suggestionDate': _dateOnly(suggestionDate),
      },
    );
  }

  static String _localizedText(BaseMultiLanguage values, String localeCode) {
    final localeValue = switch (localeCode) {
      'en' => values.en,
      'vi' => values.vi,
      'zh' => values.zh,
      'ja' => values.ja,
      'ko' => values.ko,
      _ => '',
    }.trim();
    if (localeValue.isNotEmpty) return localeValue;

    final englishValue = values.en.trim();
    if (englishValue.isNotEmpty) return englishValue;

    return values.text.trim();
  }

  static String _dateOnly(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
