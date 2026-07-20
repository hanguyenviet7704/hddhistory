part of '../../../lesson.dart';

// Companion to the Live Activity (LiveActivityService) — a normal local
// notification, so unlike the Activity itself this works on Android too (see
// "7 · Live Activity.dc.html" design's "Return nudge" section: fires if the
// lesson stays paused too long). Only one lesson can be in flight at a time,
// so a single fixed notification id is enough — no per-course bookkeeping.
const int _liveActivityReturnNudgeNotificationId = 0x4C41_4E44; // "LAND" in hex, arbitrary but stable

const Duration liveActivityReturnNudgeDelay = Duration(minutes: 20);

/// (Re)schedules the return-nudge [delay] from now, replacing any previously
/// scheduled one — call this at Live Activity start and on every meaningful
/// progress update, so the window keeps resetting while the user is actively
/// progressing and only fires once they've genuinely stalled.
Future<void> scheduleLiveActivityReturnNudge({
  required String courseName,
  required bool isDone,
  required int minutes,
  required double progress,
  Duration delay = liveActivityReturnNudgeDelay,
}) async {
  try {
    final lesson = l10n.lesson;
    await NotificationService.scheduleLocal(
      NotificationScheduleRequest(
        notification: NotificationRequest(
          id: _liveActivityReturnNudgeNotificationId,
          title: isDone ? lesson.liveActivityDoneNotifTitle : lesson.liveActivityNudgeNotifTitle,
          body: isDone ? lesson.liveActivityDoneNotifBody(course: courseName) : lesson.liveActivityNudgeNotifBody(count: minutes),
          // The design's return-nudge shows the course progress bar (Android
          // renders it; iOS has no native progress-bar notification).
          progress: (progress.clamp(0, 1) * 100),
        ),
        scheduledAt: DateTime.now().add(delay),
      ),
    );
  } catch (error) {
    // Best-effort, same as habit reminders — must never block the lesson flow.
    LogDev.warning('[LiveActivity] scheduleReturnNudge failed: $error');
  }
}

Future<void> cancelLiveActivityReturnNudge() async {
  try {
    await NotificationService.cancel(_liveActivityReturnNudgeNotificationId);
  } catch (error) {
    LogDev.warning('[LiveActivity] cancelReturnNudge failed: $error');
  }
}
