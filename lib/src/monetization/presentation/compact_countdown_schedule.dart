part of '../monetization.dart';

/// The compact paywall's countdown deadline, computed PER READER.
///
/// The sheet used to run on `compactPaywall.endAtUtc` — one absolute instant
/// shared by everyone. That works for a real campaign with a real end, but it
/// means somebody who first opens the sheet an hour before it lapses gets an
/// hour, and everybody who arrives afterwards sees no clock at all.
///
/// Anchored instead on the first time THIS reader saw the sheet, so each one
/// gets the full window from the moment they were offered it.
///
/// ## The cycle restarts, and that is a deliberate product decision
///
/// When the window has lapsed, the next open stamps a fresh anchor and the
/// clock starts over rather than staying expired. That makes the deadline a
/// recurring one, not a real one: a reader who comes back two days later is
/// told they have 24 hours again.
///
/// It was chosen knowingly, with the alternative — let it lapse and simply hide
/// the clock, the way `endAtUtc` behaves — on the table. Two things follow, and
/// whoever revisits this should weigh them rather than treat the restart as an
/// oversight to tidy up: a reader who notices the reset learns the urgency is
/// theatre, and App Review has rejected countdowns that never actually end.
@lazySingleton
class CompactCountdownSchedule {
  final MonetizationLocalDataSource _local;

  CompactCountdownSchedule(this._local);

  /// Falls back to a day when config says nothing.
  static const int defaultHours = 24;

  /// The instant this reader's current window closes, stamping a new anchor
  /// when there isn't a live one. Returns null only for a nonsensical
  /// `hours`, where a countdown would be meaningless.
  Future<DateTime?> resolveDeadline({int hours = defaultHours}) async {
    if (hours <= 0) return null;

    final now = DateTime.now().toUtc();
    final stored = await _local.getCompactCountdownAnchorEpochMs();

    if (stored != null) {
      final deadline = DateTime.fromMillisecondsSinceEpoch(stored, isUtc: true).add(Duration(hours: hours));
      // Still inside the window: keep counting toward the SAME instant, so
      // reopening the sheet does not quietly hand out extra time.
      if (deadline.isAfter(now)) return deadline;
    }

    await _local.setCompactCountdownAnchorEpochMs(now.millisecondsSinceEpoch);
    return now.add(Duration(hours: hours));
  }
}
