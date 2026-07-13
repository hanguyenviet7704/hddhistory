part of '../../habit.dart';

/// QA-only toggles for exercising habit flows that are otherwise gated by
/// server/date conditions. Every effect is double-guarded ([_qaEnabled]) so a
/// flag left `true` can NEVER reach a production build — it only takes effect
/// in a debug build of a non-prod flavor.
class HabitQaFlags {
  const HabitQaFlags._();

  /// True only in a debug build of a non-prod flavor. All QA effects AND this
  /// together, so production users are never affected even if a flag is left on.
  static bool get _qaEnabled => kDebugMode && F.appFlavor != Flavor.prod;

  /// Force the Weekly recap to open regardless of the server's `isRecapDay`
  /// (§9.9). The recap normally shows only on the server's recap day, so QA
  /// can't see it on demand — flip this to `true` to open it any day.
  /// Requires at least one active habit (the screen has nothing to show
  /// otherwise). Remember to set back to `false` before committing.
  static const bool _forceWeeklyRecap = true;

  static bool get forceWeeklyRecap => _qaEnabled && _forceWeeklyRecap;
}
