part of '../../coach.dart';

/// Owns the bubble on the shell.
///
/// A single self-contained widget so [ScaffoldLayout] gains one line rather
/// than a cubit, a listener and a Positioned. It is NOT part of the popup-host
/// chain and deliberately so: the bubble never opens itself, which is exactly
/// what keeps the Coach out of the cold-start scramble between the week-recap
/// poster, the gift popup, the streak toast and the Home promo.
class CoachBubbleHost extends StatelessWidget {
  /// Bottom of the bubble, already clear of the floating nav bar.
  final double bottomInset;

  const CoachBubbleHost({super.key, required this.bottomInset});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CoachBubbleCubit>(
      create: (_) => AppDI.injector.get<CoachBubbleCubit>(),
      child: _CoachBubbleHostBody(bottomInset: bottomInset),
    );
  }
}

class _CoachBubbleHostBody extends StatefulWidget {
  final double bottomInset;

  const _CoachBubbleHostBody({required this.bottomInset});

  @override
  State<_CoachBubbleHostBody> createState() => _CoachBubbleHostBodyState();
}

class _CoachBubbleHostBodyState extends State<_CoachBubbleHostBody> {
  /// The door we last asked about.
  ///
  /// Guards the refresh: without it the fetch fires from `build`, its result
  /// emits, the emit rebuilds, and the rebuild fetches again — an endless loop
  /// hammering the endpoint, which is what made the app feel like it was
  /// throwing you out of the tab.
  CoachEntry? _asked;

  /// Which door the current tab is, or null where the Coach does not belong.
  ///
  /// Home and the Habit tab (owner, 2026-09-04: "thiếu coach ở màn habit
  /// này"). Both open the same HOME session — the conversation, and the
  /// practice pill that picks a habit out of the kho. The Habit DOOR proper
  /// (luồng 5, `CoachEntry.habit`) belongs to one habit's own screen and is
  /// opened from the practice picker there, not from this bubble.
  CoachEntry? _entryFor(String routeName) {
    if (routeName == RouteNamed.home || routeName == RouteNamed.habit) return CoachEntry.home;

    return null;
  }

  /// The sheet, and what the reader chose on the way out.
  ///
  /// Lives on the STATE, not the bubble's builder: PageCubit's route name gets
  /// re-anchored by overlays while the sheet is up, the selector below collapses
  /// to a shrink, and the builder's element dies — so a courseId handed back
  /// after the modal closed was silently dropped by its `context.mounted` guard.
  /// The State survives that collapse, and navigation itself goes through the
  /// app-level context, which outlives even this host.
  Future<void> _openSheet(CoachEntry entry) async {
    final courseId = await showCoachSheet(context, entry: entry);
    LogDev.data('[CoachDbg] sheet closed: courseId=$courseId mounted=$mounted'); // TEMP-DEBUG

    if (courseId != null) {
      final navContext = AppConfig.instance.context ?? (mounted ? context : null);
      if (navContext != null && navContext.mounted) {
        AppDI.injector.get<DeeplinkCubit>().openCourseRoadmapFromCoach(navContext, courseId);
      }
    }
    if (!mounted) return;

    _asked = null;
    await context.read<CoachBubbleCubit>().invalidate(entry: entry);
  }

  /// Ask once per arrival at a door, after the frame — never during build.
  void _refreshIfNeeded(BuildContext context, CoachEntry entry) {
    if (_asked == entry) return;
    _asked = entry;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CoachBubbleCubit>().refresh(entry: entry);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PageCubit, PageState, String>(
      selector: (state) => state.currentRouteName,
      builder: (context, routeName) {
        final entry = _entryFor(routeName);
        if (entry == null) {
          // Leaving the door resets the guard, so coming back asks again — the
          // dot and teaser go stale the moment a commitment is answered
          // anywhere else.
          _asked = null;

          return const SizedBox.shrink();
        }

        _refreshIfNeeded(context, entry);

        return BlocBuilder<CoachBubbleCubit, CoachBubbleState>(
          builder: (context, state) {
            // Nothing until the server has answered, so the bubble never
            // flashes in and out on first paint.
            if (!state.resolved || !state.visible) return const SizedBox.shrink();

            return CoachBubble(
              bottomInset: widget.bottomInset,
              dot: state.dot,
              // ②A quotes the reader's own commitment; ④ has no words of
              // theirs to quote yet and says "Tình huống ba tuần trước…".
              teaser: state.teaser ?? coachTeaser(context, state.teaserKey),
              // Navigating AFTER the sheet is gone, never from inside it —
              // pushing a route from under a closing modal is how a
              // navigator ends up with an orphan.
              onTap: () => _openSheet(entry),
            );
          },
        );
      },
    );
  }
}
