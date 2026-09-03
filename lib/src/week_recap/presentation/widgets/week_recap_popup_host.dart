part of '../../week_recap.dart';

/// Raises the Monday popup once, over whatever tab the reader lands on.
///
/// Lives on the shell rather than on Home, for the reason [StreakPopupHost]
/// gives: the shell outlives every tab switch, and this host also has to be
/// alive when the Library tab asks the same cubit for the banner's data.
///
/// Who decides what: the SERVER decides whether there is a week to show and
/// whether the reader has already been offered it (`viewedAt` / `dismissedAt`).
/// This widget decides only when — after the first frame, on a primary route,
/// and only if no other popup has claimed this app-open.
class WeekRecapPopupHost extends StatefulWidget {
  const WeekRecapPopupHost({super.key, required this.child});

  final Widget child;

  /// Whether this app session has already had its turn. In-memory, so it dies
  /// with the process — the server-side stamp is what makes "once" permanent.
  static bool _shownThisSession = false;

  @visibleForTesting
  static void resetSessionLatch() => _shownThisSession = false;

  @override
  State<WeekRecapPopupHost> createState() => _WeekRecapPopupHostState();
}

class _WeekRecapPopupHostState extends State<WeekRecapPopupHost> {
  /// Watches for the route becoming primary again.
  ///
  /// The first attempt runs after the first frame, but a cold start often lands
  /// somewhere the popup must not cover — a deep-linked keypoint, the paywall,
  /// or the habit weekly review, which pushes itself over Home on app open. A
  /// one-shot attempt would then drop the invitation for the whole session even
  /// though the latch was never spent. This keeps trying until the reader is
  /// somewhere it is polite to interrupt.
  StreamSubscription<PageState>? _routeSub;

  /// Guards against two attempts overlapping while the fetch is in flight.
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_maybeShow()));
    _routeSub = AppDI.injector.get<PageCubit>().stream.listen((state) {
      if (state.isPrimaryRoute) unawaited(_maybeShow());
    });
  }

  @override
  void dispose() {
    unawaited(_routeSub?.cancel());
    _routeSub = null;
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (!mounted || _checking || WeekRecapPopupHost._shownThisSession) return;
    _checking = true;
    try {
      await _attempt();
    } finally {
      _checking = false;
    }
  }

  Future<void> _attempt() async {
    final cubit = AppDI.injector.get<WeekRecapCubit>();
    await cubit.ensureCurrentLoaded();
    if (!mounted) return;

    final recap = cubit.state.current;
    // Nothing to offer for the rest of this session — no recap, already viewed,
    // or "Để sau" pressed today (the mute holds until tomorrow, and a session
    // rarely outlives midnight). Stop listening rather than re-check on every
    // route change.
    if (recap == null || !cubit.state.shouldShowMondayPopup) {
      unawaited(_routeSub?.cancel());
      _routeSub = null;

      return;
    }

    // Not over a lesson, a paywall or a sheet. The session latch is deliberately
    // NOT spent here — the subscription above will bring us back once the reader
    // is on a screen this may interrupt.
    //
    // Resolved through the injector, not `context.read`: this host sits ABOVE
    // every route, so the route-scoped providers are below it and a `read` here
    // finds nothing. Its siblings on the shell do the same.
    if (!AppDI.injector.get<PageCubit>().state.isPrimaryRoute) return;

    if (!AppOpenModalGate.claim('week_recap')) return;
    WeekRecapPopupHost._shownThisSession = true;
    unawaited(_routeSub?.cancel());
    _routeSub = null;

    bool? wantsToView;
    try {
      wantsToView = await WeekRecapMondayPopup.show(context, recap);
    } finally {
      AppOpenModalGate.release('week_recap');
    }
    if (wantsToView == null) return;

    // Recorded and routed HERE rather than inside the dialog: the dialog's own
    // context dies with it, and the cubit is not above it either.
    unawaited(cubit.markInteracted(viewed: wantsToView));
    if (!wantsToView || !mounted) return;
    cubit.openRecap(recap);
    const WeekRecapRoute().push(context);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
