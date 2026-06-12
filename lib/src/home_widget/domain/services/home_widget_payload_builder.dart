part of '../../home_widget.dart';

class HomeWidgetPayloadBuilder {
  static HomeWidgetPayload buildInProgress(
    HomeWidgetCourseEntity? course, {
    required String localeCode,
    required DateTime updatedAt,
    HomeWidgetTextDefaults textDefaults = const HomeWidgetTextDefaults(),
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
          'title': textDefaults.inProgressEmptyTitle,
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
        'titleTranslations': _localizedTextMap(course.title),
        'imagePathKey': HomeWidgetStorageKeys.inProgressImage,
        'completedLessons': course.completedLesson,
        'totalLessons': course.totalLesson,
        'progressText': textDefaults.progressText(completed: course.completedLesson, total: course.totalLesson),
        'progress': progress,
      },
    );
  }

  static HomeWidgetPayload buildStreak(
    HomeWidgetStreakEntity streak, {
    String localeCode = 'en',
    required DateTime updatedAt,
    HomeWidgetTextDefaults textDefaults = const HomeWidgetTextDefaults(),
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
        'localeCode': localeCode,
        'currentStreak': streak.currentStreak,
        'countText': textDefaults.streakCountText(streak.currentStreak),
        'subtitle': streak.currentStreak > 0 ? textDefaults.streakActiveSubtitle : textDefaults.streakEmptySubtitle,
        'weekStudy': weekStudy,
        'weekLabels': textDefaults.weekLabels.take(7).toList(growable: false),
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
    HomeWidgetTextDefaults textDefaults = const HomeWidgetTextDefaults(),
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
          'title': textDefaults.suggestExhaustedTitle,
          'subtitle': textDefaults.suggestExhaustedSubtitle,
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
        'label': textDefaults.suggestLabel,
        'title': _localizedText(course.title, localeCode),
        'titleTranslations': _localizedTextMap(course.title),
        'description': _localizedText(course.description, localeCode),
        'descriptionTranslations': _localizedTextMap(course.description),
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

    return [values.en, values.vi, values.zh, values.ja, values.ko].map((value) => value.trim()).firstWhere((value) => value.isNotEmpty, orElse: () => '');
  }

  static Map<String, String> _localizedTextMap(BaseMultiLanguage values) {
    return {
      'en': values.en,
      'vi': values.vi,
      'zh': values.zh,
      'ja': values.ja,
      'ko': values.ko,
    }.map((key, value) => MapEntry(key, value.trim()))..removeWhere((_, value) => value.isEmpty);
  }

  static String _dateOnly(DateTime dateTime) {
    return '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}
