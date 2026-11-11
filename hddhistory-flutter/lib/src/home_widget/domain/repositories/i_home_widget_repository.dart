part of '../../home_widget.dart';

abstract class IHomeWidgetRepository {
  TaskEither<AppException, List<HomeWidgetSyncResult>> syncAll(HomeWidgetSyncParams params);

  TaskEither<AppException, HomeWidgetSyncResult> syncInProgress(HomeWidgetSyncParams params);

  TaskEither<AppException, HomeWidgetSyncResult> syncStreak(HomeWidgetSyncParams params);

  TaskEither<AppException, HomeWidgetSyncResult> syncSuggestCourse(HomeWidgetSyncParams params);

  TaskEither<AppException, HomeWidgetSyncResult> clearStoredWidgets();
}
