part of '../../home_widget.dart';

enum HomeWidgetType {
  inProgressCourse('in_progress_course'),
  weeklyStreak('weekly_streak'),
  suggestCourse('suggest_course');

  const HomeWidgetType(this.value);

  final String value;

  static HomeWidgetType fromValue(String value) {
    return tryFromValue(value) ?? HomeWidgetType.inProgressCourse;
  }

  static HomeWidgetType? tryFromValue(String value) {
    for (final type in HomeWidgetType.values) {
      if (type.value == value) return type;
    }
    return null;
  }
}

enum HomeWidgetPayloadState {
  ready('ready'),
  empty('empty'),
  exhausted('exhausted');

  const HomeWidgetPayloadState(this.value);

  final String value;

  static HomeWidgetPayloadState fromValue(String value) {
    return tryFromValue(value) ?? HomeWidgetPayloadState.empty;
  }

  static HomeWidgetPayloadState? tryFromValue(String value) {
    for (final state in HomeWidgetPayloadState.values) {
      if (state.value == value) return state;
    }
    return null;
  }
}

enum HomeWidgetSyncStatus {
  updated,
  preserved,
  cleared,
  failed,
}

class HomeWidgetStorageKeys {
  static const inProgressPayload = 'meup_home_widget_in_progress_v1';
  static const streakPayload = 'meup_home_widget_streak_v1';
  static const suggestCoursePayload = 'meup_home_widget_suggest_course_v1';
  static const inProgressImage = 'meup_home_widget_in_progress_image';
  static const suggestCourseImage = 'meup_home_widget_suggest_course_image';
  static const bookAsset = 'meup_home_widget_book_asset';
  static const certificateAsset = 'meup_home_widget_certificate_asset';
  static const flameAsset = 'meup_home_widget_flame_asset';
  static const suggestionDate = 'meup_home_widget_suggest_course_date';

  static const allKeys = [
    inProgressPayload,
    streakPayload,
    suggestCoursePayload,
    inProgressImage,
    suggestCourseImage,
    bookAsset,
    certificateAsset,
    flameAsset,
    suggestionDate,
  ];
}

class HomeWidgetNativeNames {
  static const inProgressIOSName = 'MeupInProgressWidget';
  static const streakIOSName = 'MeupStreakWidget';
  static const suggestCourseIOSName = 'MeupSuggestCourseWidget';
  static const inProgressAndroidName = 'com.eup.meup.homewidget.InProgressHomeWidgetReceiver';
  static const streakAndroidName = 'com.eup.meup.homewidget.StreakHomeWidgetReceiver';
  static const suggestCourseAndroidName = 'com.eup.meup.homewidget.SuggestCourseHomeWidgetReceiver';

  static String iOSName(HomeWidgetType type) {
    return switch (type) {
      HomeWidgetType.inProgressCourse => inProgressIOSName,
      HomeWidgetType.weeklyStreak => streakIOSName,
      HomeWidgetType.suggestCourse => suggestCourseIOSName,
    };
  }

  static String androidName(HomeWidgetType type) {
    return switch (type) {
      HomeWidgetType.inProgressCourse => inProgressAndroidName,
      HomeWidgetType.weeklyStreak => streakAndroidName,
      HomeWidgetType.suggestCourse => suggestCourseAndroidName,
    };
  }
}

class HomeWidgetAppGroups {
  static const dev = 'group.com.eup.meup.dev.homewidget';
  static const stg = 'group.com.eup.meup.stg.homewidget';
  static const prod = 'group.com.eup.meup.homewidget';

  static String current() {
    return switch (F.appFlavor) {
      Flavor.dev => dev,
      Flavor.stg => stg,
      Flavor.prod => prod,
      _ => dev,
    };
  }
}
