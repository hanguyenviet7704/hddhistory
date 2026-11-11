part of '../utils.dart';

/// One app-open, one modal.
///
/// The shell stacks several independent popup hosts (import-done, win-back,
/// gift, streak) and Home adds the promo popup on top. Each has its own
/// once-per-session latch and none of them knows about the others, so two that
/// become ready in the same frame both call `showDialog` and the reader gets a
/// card on a card.
///
/// This is the shared claim they check instead. Whoever gets it shows; the
/// others give up for this session rather than queueing — a promo that arrives
/// after the reader has just been handed their week is not worth interrupting
/// them a second time for.
///
/// In-memory on purpose: "this app-open" has to die with the process. Persisting
/// it would turn "shown once today" into "shown once ever".
class AppOpenModalGate {
  const AppOpenModalGate._();

  static String? _owner;

  /// Takes the turn, or returns false if someone already has it.
  ///
  /// Call this immediately before `showDialog`, not when the host starts
  /// deciding: hosts reach their decision after a network call, and claiming
  /// early would block a sibling on behalf of a popup that then turns out to
  /// have nothing to show.
  static bool claim(String owner) {
    if (_owner != null) return false;
    _owner = owner;

    return true;
  }

  /// Hands the turn back once the modal has closed.
  static void release(String owner) {
    if (_owner == owner) _owner = null;
  }

  static bool get isClaimed => _owner != null;

  /// Test seam: a widget test cannot relaunch the app between cases.
  @visibleForTesting
  static void reset() => _owner = null;
}
