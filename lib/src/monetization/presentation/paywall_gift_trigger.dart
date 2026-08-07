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

  static const int windowDays = 7;

  /// Day-zero claim: true exactly once, at the first habit adoption ever seen
  /// on this install. Also stamps today as shown, so the day-1 open (tomorrow)
  /// is the next legal slot rather than a second popup the same evening.
  Future<bool> claimDayZero() async {
    if (await _local.getGiftDayZeroEpochMs() != null) return false;
    final now = DateTime.now();
    await _local.setGiftDayZeroEpochMs(now.millisecondsSinceEpoch);
    await _local.setGiftLastShownDay(_dayKey(now));
    return true;
  }

  /// Daily claim for the days 1–7 window. True at most once per local
  /// calendar day, and only when day zero has happened.
  Future<bool> claimDailyOpen() async {
    final epochMs = await _local.getGiftDayZeroEpochMs();
    if (epochMs == null) return false;

    final now = DateTime.now();
    final dayZero = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final elapsedDays = DateTime(now.year, now.month, now.day).difference(DateTime(dayZero.year, dayZero.month, dayZero.day)).inDays;
    if (elapsedDays < 1 || elapsedDays > windowDays) return false;

    final today = _dayKey(now);
    if (await _local.getGiftLastShownDay() == today) return false;
    await _local.setGiftLastShownDay(today);
    return true;
  }

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

  // An unloaded profile reads as non-premium; showing an upsell to someone who
  // already paid is worse than skipping a day, so wait for a real answer.
  final user = AppDI.injector.get<ProfileCubit>().state.user;
  if (user.id.isEmpty || user.isPremium) return;

  final schedule = AppDI.injector.get<GiftPopupSchedule>();
  final shouldShow = dayZeroEvent ? await schedule.claimDayZero() : await schedule.claimDailyOpen();
  if (!shouldShow || !context.mounted) return;

  final opened = await PaywallGiftPopup.show(context);
  if (!opened || !context.mounted) return;

  iapCubit.markPaywallForcedCompact();
  await const PaywallRoute().push(context);
}

/// Post-frame wrapper for initState-style call sites.
void scheduleGiftPopupCheck(BuildContext context, {required bool dayZeroEvent}) {
  SchedulerBinding.instance.addPostFrameCallback((_) {
    if (context.mounted) maybeShowGiftPopup(context, dayZeroEvent: dayZeroEvent);
  });
}
