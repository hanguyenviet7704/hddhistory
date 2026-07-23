part of '../../habit.dart';

/// Analytics for the Habit feature (§9). Mirrors [OnboardV2Tracking]'s SAFE
/// dispatch shape: every call is fire-and-forget, wrapped in try/catch +
/// `.catchError` + `unawaited`, so a tracking failure can never break the UI
/// flow it is attached to.
class HabitTracking {
  const HabitTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  static void setUserProperties(Map<String, dynamic> properties) {
    final props = <String, dynamic>{...properties}..removeWhere((_, value) => value == null || (value is String && value.trim().isEmpty));
    if (props.isEmpty) return;
    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.setUserProperties(props).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// Course title from the FULL catalog (HomeCubit.skillsets) — same lookup the
  /// tracker cluster titles use. Returns '' for a missing/empty course id or if
  /// the catalog isn't ready yet (never throws).
  static String _courseName(String? courseId) {
    if (courseId == null || courseId.isEmpty) return '';
    try {
      return AppDI.injector.get<HomeCubit>().state.skillsets.resolveCourseByCourseId(courseId).title.text;
    } catch (_) {
      return '';
    }
  }

  /// The shared habit identity block ({habit_id, habit_name, course_id,
  /// course_name}) carried by every per-habit event.
  static Map<String, dynamic> habitParams(UserHabitEntity habit) {
    return {
      'habit_id': habit.id,
      'habit_name': habit.displayTitle,
      'course_id': habit.sourceCourseId ?? '',
      'course_name': _courseName(habit.sourceCourseId),
    };
  }

  static Map<String, dynamic> _courseParams(String? courseId) {
    return {
      'course_id': courseId ?? '',
      'course_name': _courseName(courseId),
    };
  }

  //* Tracker (Habit tab)
  static void scrView({required String source, required bool isEmpty}) {
    track(TrackingKey.habitScrView, parameters: {'source': source, 'is_empty': isEmpty});
  }

  static void itemOpen(UserHabitEntity habit) {
    track(TrackingKey.habitItemOpen, parameters: habitParams(habit));
  }

  static void taskCheck(UserHabitEntity habit) {
    track(TrackingKey.habitTaskCheck, parameters: {...habitParams(habit), 'checked': habit.todayDone});
  }

  static void emptyCourseClick() => track(TrackingKey.habitEmptyCourseClick);

  static void editOpen() => track(TrackingKey.habitEditOpen);

  //* Check-in + diary sheet
  static void noteCheckin(UserHabitEntity habit, {required bool hasNote}) {
    track(TrackingKey.habitNoteCheckin, parameters: {...habitParams(habit), 'has_note': hasNote});
  }

  static void noteClose() => track(TrackingKey.habitNoteClose);

  //* Habit detail
  static void detailScrView(UserHabitEntity habit, {required int completionRate, required int currentLoops}) {
    track(TrackingKey.habitDetailScrView, parameters: {...habitParams(habit), 'completion_rate': completionRate, 'current_loops': currentLoops});
  }

  static void detailClose() => track(TrackingKey.habitDetailClose);

  //* Edit-habit sheet
  static void editScrView({required int activeCount, required int inactiveCount}) {
    track(TrackingKey.habitEditScrView, parameters: {'active_count': activeCount, 'inactive_count': inactiveCount});
  }

  static void editToggle(UserHabitEntity habit, {required bool active}) {
    track(TrackingKey.habitEditToggle, parameters: {...habitParams(habit), 'active_state': active ? 'active' : 'inactive'});
  }

  static void editClose({required int activeCount}) {
    track(TrackingKey.habitEditClose, parameters: {'active_count': activeCount});
  }

  //* Re-anchor screen
  static void reanchorScrView({required String courseId}) {
    track(TrackingKey.habitReanchorScrView, parameters: _courseParams(courseId));
  }

  static void reanchorSelect({required String anchorId, required String anchorName, required String courseId}) {
    track(TrackingKey.habitReanchorSelect, parameters: {'anchor_id': anchorId, 'anchor_name': anchorName, ..._courseParams(courseId)});
  }

  //* Adopt / start-habit screen
  static void startScrView({String? anchorId, String? anchorName, String? courseId}) {
    track(TrackingKey.habitStartScrView, parameters: {'anchor_id': anchorId, 'anchor_name': anchorName, ..._courseParams(courseId)});
  }

  static void startAdd({
    String? anchorId,
    String? anchorName,
    String? courseId,
    required String habitId,
    required String habitName,
    required bool isFullSlot,
  }) {
    track(TrackingKey.habitStartAdd, parameters: {
      'anchor_id': anchorId,
      'anchor_name': anchorName,
      ..._courseParams(courseId),
      'habit_id': habitId,
      'habit_name': habitName,
      'is_full_slot': isFullSlot,
    });
  }

  static void startSkip({
    String? anchorId,
    String? anchorName,
    String? courseId,
    required String habitId,
    required String habitName,
  }) {
    track(TrackingKey.habitStartSkip, parameters: {
      'anchor_id': anchorId,
      'anchor_name': anchorName,
      ..._courseParams(courseId),
      'habit_id': habitId,
      'habit_name': habitName,
      'is_full_slot': false,
    });
  }

  //* Habit-added popup
  static void addedScrView() => track(TrackingKey.habitAddedScrView);

  static void addedGoHabit() => track(TrackingKey.habitAddedGoHabit);

  static void addedContinue() => track(TrackingKey.habitAddedContinue);

  //* Slot-full upgrade sheet
  static void slotsFullScrView() => track(TrackingKey.habitSlotsFullScrView);

  static void slotsUnlimitedClick() => track(TrackingKey.habitSlotsUnlimitedClick);

  static void slotsManageClick() => track(TrackingKey.habitSlotsManageClick);

  static void slotsFullClose() => track(TrackingKey.habitSlotsFullClose);

  //* Manage-slots screen
  static void manageScrView() => track(TrackingKey.habitManageScrView);

  static void manageToggle(UserHabitEntity habit, {required bool active}) {
    track(TrackingKey.habitManageToggle, parameters: {...habitParams(habit), 'active_state': active ? 'active' : 'inactive'});
  }

  static void manageConfirm() => track(TrackingKey.habitManageConfirm);

  static void manageBack() => track(TrackingKey.habitManageBack);
}
