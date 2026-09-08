import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';

/// The gift popup's calendar: it may show at the moment the FIRST habit is
/// adopted (day zero), plus on app open — never for premium accounts.
///
/// The app-open trigger has two modes, chosen in config
/// ([GiftOpenFrequency]). `oncePerDay` is the original spec-sheet rule: the
/// first open of each day, days 1–7, and only after day zero. `everyOpen`
/// drops both the day-zero requirement and the window, and is capped instead
/// by a minimum gap in minutes — because the caller re-checks on every
/// `resumed` event, so "every open" without a floor means a popup every time
/// the reader glances at another app.
///
/// This class owns only the schedule. Whether a campaign exists, whether the
/// account is premium, and what the popup looks like are the caller's problem
/// ([maybeShowGiftPopup]) — so the date arithmetic stays testable without DI
/// theatre around config and profile state.
@lazySingleton
class GiftPopupSchedule {
  final MonetizationLocalDataSource _local;

  GiftPopupSchedule(this._local);

  /// Used when no campaign config is in hand. The window itself is admin
  /// config now ([PaywallGiftCampaignEntity.windowDays]) — it lived here as a
  /// constant, which made "run it for five days this month" a code change, a
  /// release and a store review for a purely marketing number.
  static const int defaultWindowDays = 7;

  /// Fallback gap for [canShowEveryOpen] when no campaign config is in hand.
  /// Mirrors [PaywallGiftCampaignEntity.minGapMinutes]'s own default.
  static const int defaultMinGapMinutes = 30;

  /// Asking and spending are separate on purpose.
  ///
  /// They used to be one "claim" call that wrote the mark and returned true, so
  /// anything that stopped the popup AFTER that point — a modal already on
  /// screen, a context torn down between the check and the show — burned the
  /// slot anyway. For the daily window that costs a day; for day zero, which
  /// happens once per install, it costs the trigger entirely. The streak popup
  /// makes the same distinction and says why in `StreakPopupHost`.
  ///
  /// So: `canShow*` only reads, `mark*Shown` only writes, and the caller writes
  /// exactly when the popup really went up.

  /// True until the first habit adoption ever seen on this install.
  Future<bool> canShowDayZero() async => await _local.getGiftDayZeroEpochMs() == null;

  /// True at most once per local calendar day inside the days 1–7 window, and
  /// only after day zero has happened.
  Future<bool> canShowDailyOpen({int windowDays = defaultWindowDays}) async {
    final epochMs = await _local.getGiftDayZeroEpochMs();
    if (epochMs == null) return false;

    final now = DateTime.now();
    final dayZero = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final elapsedDays = DateTime(now.year, now.month, now.day).difference(DateTime(dayZero.year, dayZero.month, dayZero.day)).inDays;
    if (elapsedDays < 1 || elapsedDays > windowDays) return false;

    return await _local.getGiftLastShownDay() != _dayKey(now);
  }

  /// True when the last showing — in either mode — is at least
  /// [minGapMinutes] old. Reads no day zero and no window: this mode is for
  /// every non-premium reader from their first open onwards, so the gap is the
  /// only gate.
  ///
  /// A gap of 0 really does mean every resume; the guard against a torn
  /// double-`resumed` is the caller's `_busy` flag, not this arithmetic.
  Future<bool> canShowEveryOpen({int minGapMinutes = defaultMinGapMinutes}) async {
    final lastShownMs = await _local.getGiftLastShownEpochMs();
    // Never shown on this install, so nothing to wait out. Note this reads the
    // epoch mark alone: an install that only ever ran the oncePerDay mode has a
    // day key but no epoch, and gets one free showing when the mode is switched
    // — the alternative is holding a fresh `everyOpen` run back for a gap it
    // has no record of.
    if (lastShownMs == null) return true;
    if (minGapMinutes <= 0) return true;

    final elapsed = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastShownMs));
    // A device clock moved backwards leaves a mark in the future, which would
    // otherwise lock the popup out until real time catches up.
    if (elapsed.isNegative) return true;
    return elapsed.inMinutes >= minGapMinutes;
  }

  /// Stamps day zero AND the shown marks, so the day-1 open (tomorrow) is the
  /// next legal slot rather than a second popup the same evening.
  Future<void> markDayZeroShown() async {
    await _local.setGiftDayZeroEpochMs(DateTime.now().millisecondsSinceEpoch);
    await markOpenShown();
  }

  /// Stamps BOTH marks — the day key the `oncePerDay` window reads and the
  /// epoch the gap reads — so flipping the config's mode either way lands on a
  /// mark it understands instead of a free showing.
  Future<void> markOpenShown() async {
    final now = DateTime.now();
    await _local.setGiftLastShownDay(_dayKey(now));
    await _local.setGiftLastShownEpochMs(now.millisecondsSinceEpoch);
  }

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/// Shows the gift popup when every gate agrees, and routes an accepted gift to
/// the ABBREVIATED paywall — the spec is explicit that the popup opens the
/// compact sheet, regardless of how the entry-point table is configured.
///
/// Call with [dayZeroEvent] true from a habit-adoption success, false from an
/// app-open surface (home). Silently does nothing when: no campaign in config,
/// the matching trigger is switched off, profile not loaded yet, account is
/// premium, or the schedule says this slot is already spent — which means
/// "already shown today, or outside days 1–7" in `oncePerDay` mode, and
/// "shown less than `minGapMinutes` ago" in `everyOpen` mode.
Future<void> maybeShowGiftPopup(BuildContext context, {required bool dayZeroEvent}) async {
  final iapCubit = AppDI.injector.get<IapCubit>();
  final campaign = iapCubit.resolvedPaywallConfig.giftCampaign;
  if (campaign == null) return;

  // Each trigger has its own switch, so a run can keep the day-0 moment without
  // the daily reminder, or the reverse, without switching the campaign off.
  final triggerEnabled = dayZeroEvent ? campaign.triggerOnFirstHabit : campaign.triggerOnDailyOpen;
  if (!triggerEnabled) return;

  // A running sale event owns the screen. This popup's whole payload is the
  // COMPACT sheet, which sale events never restyle — so showing it mid-campaign
  // means putting a second, cheaper-looking, NON-sale offer in front of someone
  // the campaign is already selling to. Both triggers are silenced, and the
  // slot is deliberately NOT spent: the campaign ends, and day 3 of the gift
  // window is still day 3.
  if (iapCubit.resolvedPaywallConfig.hasActiveSaleEventAt(DateTime.now())) return;

  // An unloaded profile reads as non-premium; showing an upsell to someone who
  // already paid is worse than skipping a day, so wait for a real answer.
  final user = AppDI.injector.get<ProfileCubit>().state.user;
  if (user.id.isEmpty || user.isPremium) return;

  final schedule = AppDI.injector.get<GiftPopupSchedule>();
  final everyOpen = campaign.openFrequency == GiftOpenFrequency.everyOpen;
  final canShow = dayZeroEvent
      ? await schedule.canShowDayZero()
      : everyOpen
          ? await schedule.canShowEveryOpen(minGapMinutes: campaign.minGapMinutes)
          : await schedule.canShowDailyOpen(windowDays: campaign.windowDays);
  if (!canShow || !context.mounted) return;

  // Never cover a sheet or dialog the reader is already dealing with. The slot
  // is deliberately NOT spent here, so the popup still gets its turn on the next
  // resume — same rule, and same reasoning, as the streak toast.
  if (LearningStreakModalGuard.hasBlockingModal(context)) return;

  // Spent only now that the popup is actually going up.
  if (dayZeroEvent) {
    await schedule.markDayZeroShown();
  } else {
    await schedule.markOpenShown();
  }
  if (!context.mounted) return;

  // The sheet's gift_trigger vocabulary — the bool is the trigger, so both
  // gift events are reported here where it is in scope, not inside the popup
  // (which never learns why it was shown). The two app-open modes report
  // separately on purpose: one funnel mixing "once a day for a week" with
  // "every open forever" can't tell a better offer from a louder one.
  final giftTrigger = dayZeroEvent
      ? 'add_first_habit'
      : everyOpen
          ? 'app_every_open'
          : 'app_first_open_d1_d7';
  PaywallTracking.giftScrView(trigger: giftTrigger);

  final opened = await PaywallGiftPopup.show(context);
  if (!opened || !context.mounted) return;
  PaywallTracking.giftOpenClick(trigger: giftTrigger);

  iapCubit.forcePaywallVariant(PaywallProductVariant.compact);
  // The paywall this opens inherits the trigger as its `source`: no entry
  // point names the gift popup, and the sheet's source set for the compact
  // sheet and the success popup is exactly this vocabulary. Cleared with the
  // variant override in PaywallPage.dispose.
  iapCubit.setPaywallSourceOverride(giftTrigger);
  await const PaywallRoute().push(context);
}

/// Post-frame wrapper for initState-style call sites.
void scheduleGiftPopupCheck(BuildContext context, {required bool dayZeroEvent}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) maybeShowGiftPopup(context, dayZeroEvent: dayZeroEvent);
  });
}
