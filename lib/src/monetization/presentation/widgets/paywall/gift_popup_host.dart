part of '../../../monetization.dart';

/// Owns the gift popup's "first app-open of the day" trigger for days 1–7.
///
/// Lives on the shell rather than on Home, for the reason [StreakPopupHost]
/// spells out: the shell survives tab switches, so the check still runs for a
/// reader who comes back into Explore, Habit or Profile rather than Home.
///
/// It listens for RESUME, which is the part that was missing. The trigger used
/// to sit in `HomePage.initState`, so it only ever fired on a cold start — and
/// on a phone a cold start happens when the OS has evicted the app, not when the
/// reader opens it. Somebody who leaves HDDhistory in the background overnight, the
/// ordinary case, came back the next day to nothing.
///
/// Mounting also fires the check once, which covers the cold start that
/// `HomePage` used to handle. One owner rather than two paths that drift.
class GiftPopupHost extends StatefulWidget {
  const GiftPopupHost({super.key, required this.child});

  final Widget child;

  @override
  State<GiftPopupHost> createState() => _GiftPopupHostState();
}

class _GiftPopupHostState extends State<GiftPopupHost> with WidgetsBindingObserver {
  /// Guards against a second pass while the first is still awaiting storage or
  /// the popup itself — iOS can deliver `resumed` more than once around a
  /// system prompt, and both passes would otherwise race for the same slot.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_check());
  }

  Future<void> _check() async {
    if (_busy || !mounted) return;
    _busy = true;
    try {
      // On a cold start this check used to LOSE the race against the config
      // fetch: post-frame runs long before the HTTP response lands, and the
      // Remote Config fallback carries no `giftCampaign`, so the campaign read
      // as OFF on every launch and the popup could only ever fire on a
      // background→resume. When the resolved config has no campaign, wait for
      // the real one (this shares the fetch app start already fired) before
      // deciding.
      final iapCubit = AppDI.injector.get<IapCubit>();
      if (iapCubit.resolvedPaywallConfig.giftCampaign == null) {
        await iapCubit.prefetchPaywallConfig();
      }
      if (!mounted) return;

      // Every gate — campaign configured, non-premium, inside the 1–7 window,
      // not already shown today, nothing else on screen — lives in here.
      await maybeShowGiftPopup(context, dayZeroEvent: false);
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
