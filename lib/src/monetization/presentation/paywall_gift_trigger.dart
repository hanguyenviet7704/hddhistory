import 'package:flutter/scheduler.dart';
import 'package:injectable/injectable.dart';
import 'package:meup/meup.dart';

/// The gift popup's calendar, per the paywall spec sheet: it may show at the
/// moment the FIRST habit is adopted (day zero), then once per day on the
/// first app-open of days 1–7 — never for premium accounts, never twice in a
/// day, never outside the campaign window.
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

  /// Stamps day zero AND today, so the day-1 open (tomorrow) is the next legal
  /// slot rather than a second popup the same evening.
  Future<void> markDayZeroShown() async {
    final now = DateTime.now();
    await _local.setGiftDayZeroEpochMs(now.millisecondsSinceEpoch);
    await _local.setGiftLastShownDay(_dayKey(now));
  }

  Future<void> markDailyOpenShown() async => _local.setGiftLastShownDay(_dayKey(DateTime.now()));

  String _dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
}

/// Shows the gift popup when every gate agrees, and routes an accepted gift to
/// the ABBREVIATED paywall — the spec is explicit that the popup opens the
/// compact sheet, regardless of how the entry-point table is configured.
///
/// Call with [dayZeroEvent] true from a habit-adoption success, false from an
/// app-open surface (home). Silently does nothing when: no campaign in config,
/// outside the campaign window, profile not loaded yet, account is premium, or
/// the schedule says today already had its showing.
Future<void> maybeShowGiftPopup(BuildContext context, {required bool dayZeroEvent}) async {
  final iapCubit = AppDI.injector.get<IapCubit>();
  final campaign = iapCubit.resolvedPaywallConfig.giftCampaign;
  if (campaign == null) return;

  // Each trigger has its own switch, so a run can keep the day-0 moment without
  // the daily reminder, or the reverse, without switching the campaign off.
  final triggerEnabled = dayZeroEvent ? campaign.triggerOnFirstHabit : campaign.triggerOnDailyOpen;
  if (!triggerEnabled) return;

  // An unloaded profile reads as non-premium; showing an upsell to someone who
  // already paid is worse than skipping a day, so wait for a real answer.
  final user = AppDI.injector.get<ProfileCubit>().state.user;
  if (user.id.isEmpty || user.isPremium) return;

  final schedule = AppDI.injector.get<GiftPopupSchedule>();
  final canShow = dayZeroEvent
      ? await schedule.canShowDayZero()
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
    await schedule.markDailyOpenShown();
  }
  if (!context.mounted) return;

  // The sheet's gift_trigger vocabulary — the bool is the trigger, so both
  // gift events are reported here where it is in scope, not inside the popup
  // (which never learns why it was shown).
  final giftTrigger = dayZeroEvent ? 'add_first_habit' : 'app_first_open_d1_d7';
  PaywallTracking.giftScrView(trigger: giftTrigger);

  final opened = await PaywallGiftPopup.show(context);
  if (!opened || !context.mounted) return;
  PaywallTracking.giftOpenClick(trigger: giftTrigger);

  iapCubit.forcePaywallVariant(PaywallProductVariant.compact);
  await const PaywallRoute().push(context);
}

/// Post-frame wrapper for initState-style call sites.
void scheduleGiftPopupCheck(BuildContext context, {required bool dayZeroEvent}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) maybeShowGiftPopup(context, dayZeroEvent: dayZeroEvent);
  });
}
