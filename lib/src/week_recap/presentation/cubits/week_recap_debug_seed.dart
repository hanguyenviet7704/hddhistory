part of '../../week_recap.dart';

/// TEMP-DEBUG — delete this file, its `part` line, and the `weekOffset` argument
/// in [WeekRecapRepository.getCurrent] once the feature has been reviewed.
///
/// Points `week-recap/current` at the week STILL IN PROGRESS instead of the
/// finished one. The API returns that as a live preview — computed on every
/// call, never stored, never numbered — so a habit check-in filed in the app
/// right now shows up on the poster immediately. That is the only way to watch
/// real mood data travel end to end without waiting for Monday.
///
/// Off means the real product behaviour: last week, from the stored snapshot.
const bool kWeekRecapDebugPreviewCurrentWeek = true;

/// 0 = the week in progress (preview), 1 = the finished week (real behaviour).
int get weekRecapWeekOffset =>
    kDebugMode && kWeekRecapDebugPreviewCurrentWeek ? 0 : 1;
