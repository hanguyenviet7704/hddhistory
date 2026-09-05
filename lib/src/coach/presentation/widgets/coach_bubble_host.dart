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
    // Luồng 5 — the Habit tab is its own door: no mood, two pills about the
    // habit still unwritten today, and with an empty kho a course that teaches
    // a first habit. The Coach picks WHICH habit; the tab names none.
    if (routeName == RouteNamed.habit) return CoachEntry.habit;
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
    // Luồng 5 — the sheet may have written today's check-in (⟨Ghi nhận hôm
    // nay⟩, or a quiz finished in the chat). The Habit tab is sitting right
    // under it with yesterday's ticks, so reload it: the server has the row,
    // and a reader who just told the Coach what they did should see it ticked
    // without pulling to refresh (owner, 2026-09-04).
    if (entry == CoachEntry.habit) {
      unawaited(AppDI.injector.get<HabitCubit>().load(showLoading: false));
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

            return CoachBubble(
              bottomInset: widget.bottomInset,
              dot: state.dot,
              // ②A quotes the reader's own commitment; ④ has no words of
              // theirs to quote yet and says "Tình huống ba tuần trước…".
              teaser: state.teaser ?? coachTeaser(context, state.teaserKey),
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
