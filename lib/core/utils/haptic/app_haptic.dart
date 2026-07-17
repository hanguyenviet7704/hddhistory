part of '../utils.dart';

/// App-wide haptic feedback helper — a thin semantic wrapper over Flutter's
/// built-in [HapticFeedback] (iOS Taptic Engine / Android vibrator). Gives the
/// app a responsive, Duolingo-style "feel" WITHOUT any visual change: callers
/// just add one line at a key moment (a tap, a correct/wrong answer, a
/// completion). All calls are fire-and-forget and swallow platform errors, so
/// they're safe on devices/simulators without a vibrator.
abstract final class AppHaptic {
  /// Master on/off switch. Kept in sync with [HapticSettingCubit] (the
  /// persisted user setting) without needing a `BuildContext` — the cubit
  /// writes this field directly from its constructor (restored value) and
  /// from `onChange` (live toggles), so this static can be read from
  /// anywhere, including outside the widget tree.
  static bool enabled = true;

  static void _fire(Future<void> Function() action) {
    if (!enabled) return;
    try {
      // Fire-and-forget; ignore async channel errors on unsupported devices.
      action().catchError((_) {});
    } catch (_) {}
  }

  /// Fire [count] heavy impacts spaced [gapMs] apart — a punchy multi-pulse so
  /// the big moments (wrong answer, celebration) are clearly felt, not a single
  /// soft tap. Re-checks [enabled] before each pulse so a mid-pulse toggle-off
  /// stops it.
  static void _pulse(int count, {int gapMs = 90}) {
    if (!enabled) return;
    for (int i = 0; i < count; i++) {
      Future.delayed(Duration(milliseconds: i * gapMs), () {
        if (!enabled) return;
        try {
          HapticFeedback.heavyImpact().catchError((_) {});
        } catch (_) {}
      });
    }
  }

  /// Tap / selection feedback — buttons, nav tabs, toggles, picking an option,
  /// turning a reading page. A light impact (firmer + more felt than the old
  /// faint selection tick).
  static void select() => _fire(HapticFeedback.lightImpact);

  /// Subtle confirmation.
  static void light() => _fire(HapticFeedback.lightImpact);

  /// Positive result — correct answer, streak tick, habit adopted, finishing a
  /// reading section. Heavy so it lands.
  static void success() => _fire(HapticFeedback.heavyImpact);

  /// Wrong answer — a distinct double buzz.
  static void error() => _pulse(2);

  /// Celebration — lesson/keypoint complete, badge unlock. A triple buzz.
  static void celebrate() => _pulse(3);
}
