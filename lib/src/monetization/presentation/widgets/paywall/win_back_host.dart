part of '../../../monetization.dart';

/// Shows the gift popup after the reader closes the full paywall without
/// buying; accepting the gift is what opens the compact discount sheet.
///
/// The popup step is the point: someone who just declined the full paywall is
/// not re-offered a sheet outright — they are offered a GIFT, and only their own
/// tap opens the sale. Same two-step contract as [maybeShowGiftPopup], with its
/// own trigger value so the funnel reads apart from the day 0–7 campaign.
///
/// Lives on the shell for the same reason [GiftPopupHost] does: the paywall that
/// arms this is gone by the time the delay elapses, so whatever opens the popup
/// has to be something that outlives it. [IapCubit] owns the delay and the
/// per-session cap; this widget owns only the navigation, which keeps routing out
/// of the cubit.
class WinBackHost extends StatefulWidget {
  const WinBackHost({super.key, required this.child});

  final Widget child;

  @override
  State<WinBackHost> createState() => _WinBackHostState();
}

class _WinBackHostState extends State<WinBackHost> with WidgetsBindingObserver {
  /// Guards against a second open while the first is still on screen — the tick
  /// can only advance once per timer, but a rebuild mid-push would otherwise be
  /// able to race it.
  bool _busy = false;

  /// True while the app is not in the foreground. A win-back that comes due
  /// while the reader is in another app is DROPPED rather than queued: coming
  /// back to MeUp and being met by a sales sheet you never asked for reads as a
  /// bug, and the moment it was selling into has passed anyway.
  bool _backgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _backgrounded = state != AppLifecycleState.resumed;
  }

  /// The gift popup's `gift_trigger` value for this path, next to
  /// `add_first_habit` and `app_first_open_d1_d7` in the sheet's vocabulary.
  /// It also becomes the compact sheet's `source`, the way the other two do.
  static const String _kGiftTrigger = 'paywall_close';

  Future<void> _open() async {
    if (_busy || _backgrounded || !mounted) return;

    // Someone who became premium while the timer ran — restored a purchase,
    // redeemed a code — must not be sold to.
    if (AppDI.injector.get<ProfileCubit>().state.user.isPremium) return;

    // Never cover whatever the reader opened during the delay. Dropped, not
    // queued — same reasoning as [_backgrounded]: the moment has passed.
    if (LearningStreakModalGuard.hasBlockingModal(context)) return;

    _busy = true;
    try {
      final iapCubit = AppDI.injector.get<IapCubit>();
      AppService.instance.appTrackingService.trackPaywallWinBackShown(
        delaySeconds: iapCubit.resolvedPaywallConfig.winBack.delaySeconds,
      );

      // The win-back is the GIFT POPUP, not the compact sheet: the reader just
      // declined the full paywall, and the sheet only follows their own tap on
      // the gift. Every other exit ends the win-back here.
      PaywallTracking.giftScrView(trigger: _kGiftTrigger);
      final opened = await PaywallGiftPopup.show(context);
      if (!opened || !mounted) return;
      PaywallTracking.giftOpenClick(trigger: _kGiftTrigger);

      // Entry point BEFORE the source override — setPaywallEntryPoint clears
      // the override as part of its contract.
      iapCubit.setPaywallEntryPoint(PaywallEntryPoint.winBack);
      iapCubit.forcePaywallVariant(PaywallProductVariant.compact);
      iapCubit.setPaywallSourceOverride(_kGiftTrigger);
      await const PaywallRoute().push(context);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<IapCubit, IapState>(
      bloc: AppDI.injector.get<IapCubit>(),
      listenWhen: (previous, current) => previous.winBackDueTick != current.winBackDueTick,
      listener: (context, state) => unawaited(_open()),
      child: widget.child,
    );
  }
}
