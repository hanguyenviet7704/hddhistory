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

extension HomeWidgetTypeX on HomeWidgetType {
  String get storageKey {
    return switch (this) {
      HomeWidgetType.inProgressCourse => HomeWidgetStorageKeys.inProgressPayload,
      HomeWidgetType.weeklyStreak => HomeWidgetStorageKeys.streakPayload,
      HomeWidgetType.suggestCourse => HomeWidgetStorageKeys.suggestCoursePayload,
    };
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
  static const inProgressPayload = 'hddhistory_home_widget_in_progress_v1';
  static const streakPayload = 'hddhistory_home_widget_streak_v1';
  static const suggestCoursePayload = 'hddhistory_home_widget_suggest_course_v1';
  static const inProgressImage = 'hddhistory_home_widget_in_progress_image';
  static const suggestCourseImage = 'hddhistory_home_widget_suggest_course_image';
  static const bookAsset = 'hddhistory_home_widget_book_asset';
  static const certificateAsset = 'hddhistory_home_widget_certificate_asset';
  static const flameAsset = 'hddhistory_home_widget_flame_asset';
  static const suggestionDate = 'hddhistory_home_widget_suggest_course_date';
  static const localeCode = 'hddhistory_home_widget_locale_code';

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
    localeCode,
  ];
}

class HomeWidgetNativeNames {
  static const inProgressIOSName = 'HDDhistoryInProgressWidget';
  static const streakIOSName = 'HDDhistoryStreakWidget';
  static const suggestCourseIOSName = 'HDDhistorySuggestCourseWidget';
  static const inProgressAndroidName = 'com.hddhistory.app.homewidget.InProgressHomeWidgetReceiver';
  static const streakAndroidName = 'com.hddhistory.app.homewidget.StreakHomeWidgetReceiver';
  static const suggestCourseAndroidName = 'com.hddhistory.app.homewidget.SuggestCourseHomeWidgetReceiver';

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
  static const dev = 'group.com.hddhistory.app.dev.homewidget';
  static const stg = 'group.com.hddhistory.app.stg.homewidget';
  static const prod = 'group.com.hddhistory.app.homewidget';

  static String current() {
    return switch (F.appFlavor) {
      Flavor.dev => dev,
      Flavor.stg => stg,
      Flavor.prod => prod,
      _ => dev,
    };
  }
}
