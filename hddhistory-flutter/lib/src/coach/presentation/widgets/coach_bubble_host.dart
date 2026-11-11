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

  /// Analytics — bong bóng ĐÃ hiện dưới hình dạng nào rồi.
  ///
  /// Cùng vai trò với [_asked]: builder chạy lại mỗi lần shell rebuild, và bắn
  /// `coach_bubble_view` từ đó sẽ đếm một lần hiện thành hàng chục lần. Khoá
  /// gồm cả chấm và câu mời vì một bong bóng đổi từ "nghỉ" sang "ngóng" là một
  /// lần hiện khác, đáng đếm lại.
  String? _viewed;

  /// Where the teaser last said its piece — `<route>|<text>`.
  ///
  /// The LAST screen, not a set of them: the nudge gets three seconds on each
  /// screen the reader walks onto, and none at all while they stay (owner,
  /// 2026-09-16: "hết 3 giây tắt rồi thì sang màn khác vẫn hiển thị tiếp").
  /// Home, Khám phá and Thư viện are three screens here even though they share
  /// one Coach door.
  ///
  /// Comparing against the last screen rather than remembering every screen is
  /// what keeps it out of the flicker it replaced: `currentRouteName` is
  /// re-anchored by overlays (see the note on [_sheetResult]), and a wobble that
  /// lands back on the SAME name leaves this key unchanged, so nothing
  /// re-fires. Only walking to a different screen does.
  ///
  /// The text is part of the key on purpose: a teaser that CHANGED is new
  /// information and has earned its three seconds where it stands.
  String? _teaserSaid;

  /// Which door the current tab is, or null where the Coach does not belong.
  ///
  /// Home, Khám phá and Thư viện all open the HOME session — the conversation,
  /// and the practice pill that picks a habit out of the kho. The Habit tab is
  /// its own door (owner, 2026-09-04: "thiếu coach ở màn habit này").
  ///
  /// Everywhere else — Confession, Profile, and every sub-route pushed on top
  /// of a tab — the Coach does not belong and this returns null.
  CoachEntry? _entryFor(String routeName) {
    if (routeName == RouteNamed.home) return CoachEntry.home;
    // Khám phá and Thư viện share the HOME door (owner, 2026-09-05).
    //
    // The bubble was ALREADY appearing on both, and with the Home flow — but by
    // accident, not by decision: neither page claims its own route name, so
    // `currentRouteName` stayed on whatever tab the reader came from, and this
    // function read that stale name as `home`. The same omission is written up
    // at `PageCubit`'s `case 6`, where it put the bubble over the chat button.
    //
    // Naming them here makes the behaviour deliberate and, more to the point,
    // STABLE: it no longer depends on which tab the reader happened to arrive
    // from. Only the two tab roots — the shelves pushed on top of Thư viện
    // (history, saved, my lessons) are sub-routes with no bubble.
    if (routeName == RouteNamed.course || routeName == RouteNamed.library) {
      return CoachEntry.home;
    }

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
    _viewed = null;
    await context.read<CoachBubbleCubit>().invalidate(entry: entry);
  }

  /// Đếm một lần hiện, sau frame — không bao giờ trong build.
  void _trackViewIfNeeded(CoachEntry entry, CoachBubbleState state) {
    final key = '${entry.raw}|${state.dot}|${state.teaser ?? state.teaserKey ?? ''}';
    if (_viewed == key) return;
    _viewed = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoachTracking.bubbleView(entry, dot: state.dot, teaser: state.teaser != null || state.teaserKey != null);
    });
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
          //
          // `_teaserSaid` is deliberately NOT cleared here. It names the screen
          // the nudge was last said on, and a screen with no Coach at all is not
          // a place it was said — clearing it would hand the same sentence
          // another three seconds the moment the reader stepped back out of a
          // sub-route onto the tab they came from.
          _asked = null;
          _viewed = null;

          return const SizedBox.shrink();
        }

        _refreshIfNeeded(context, entry);

        return BlocBuilder<CoachBubbleCubit, CoachBubbleState>(
          builder: (context, state) {
            // Nothing until the server has answered, so the bubble never
            // flashes in and out on first paint.
            if (!state.resolved || !state.visible) return const SizedBox.shrink();

            _trackViewIfNeeded(entry, state);

            // ②A quotes the reader's own commitment; ④ has no words of
            // theirs to quote yet and says "Tình huống ba tuần trước…".
            final teaser = state.teaser ?? coachTeaser(context, state.teaserKey);
            final teaserKey = teaser == null ? null : '$routeName|$teaser';
            final showTeaser = teaserKey != null && _teaserSaid != teaserKey;

            return CoachBubble(
              bottomInset: widget.bottomInset,
              dot: state.dot,
              teaser: showTeaser ? teaser : null,
              onTeaserDone: () {
                if (!mounted || _teaserSaid == teaserKey) return;
                setState(() => _teaserSaid = teaserKey);
              },
              // Navigating AFTER the sheet is gone, never from inside it —
              // pushing a route from under a closing modal is how a
              // navigator ends up with an orphan.
              onTap: () {
                CoachTracking.bubbleClick(entry, dot: state.dot);
                _openSheet(entry);
              },
            );
          },
        );
      },
    );
  }
}
