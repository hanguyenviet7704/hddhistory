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

  /// Light tick for taps / selections — buttons, nav tabs, toggles, picking an
  /// option. The most frequent, subtlest feedback.
  static void select() => _fire(HapticFeedback.selectionClick);

  /// Subtle confirmation (light impact).
  static void light() => _fire(HapticFeedback.lightImpact);

  /// Noticeable soft bump — a correct answer, a streak tick.
  static void success() => _fire(HapticFeedback.mediumImpact);

  /// Stronger buzz — a wrong answer. (Flutter exposes no iOS "notification"
  /// haptic, so error maps to a heavy impact.)
  static void error() => _fire(HapticFeedback.heavyImpact);

  /// Celebratory / important beat — lesson or keypoint complete, badge unlock.
  static void celebrate() => _fire(HapticFeedback.heavyImpact);
}
