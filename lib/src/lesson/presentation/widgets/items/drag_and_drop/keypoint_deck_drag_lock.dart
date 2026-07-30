part of '../../../../lesson.dart';

/// Held while a gap-fill word chip is being dragged, so the keypoint card deck
/// leaves the gesture alone.
///
/// The deck swipes by watching raw pointer moves through a `Listener` — chosen
/// deliberately so a card's own text scroller and the deck can coexist (see
/// [KeypointCardShell]) — but that also puts it OUTSIDE the gesture arena,
/// where it cannot learn that a `Draggable` claimed the pointer. Dragging a chip
/// downwards therefore read as a backwards deck swipe and moved the whole stack.
///
/// A counter, not a bool: a second finger may start its own drag before the
/// first one ends, and the lock must survive until the last of them finishes.
abstract final class KeypointDeckDragLock {
  static int _activeDrags = 0;

  static bool get isActive => _activeDrags > 0;

  static void begin() => _activeDrags++;

  static void end() {
    if (_activeDrags == 0) return;
    _activeDrags--;
  }

  /// Leak guard: a `Draggable` disposed mid-drag never reports its end, and a
  /// stuck counter would disable deck swiping for the rest of the lesson. The
  /// shell clears the lock when the finger lifts, by which point any real drag
  /// is over anyway.
  static void reset() => _activeDrags = 0;
}
