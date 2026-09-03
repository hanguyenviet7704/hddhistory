part of '../utils.dart';

class ScaffoldLayout extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ScaffoldLayout({
    required this.navigationShell,
    Key? key,
  }) : super(key: key ?? const ValueKey<String>('LayoutScaffold'));

  @override
  State<ScaffoldLayout> createState() => _ScaffoldLayoutState();
}

class _ScaffoldLayoutState extends State<ScaffoldLayout> {
  // Maps visual tab index (0-4) to shell branch index.
  // Tab 0 Home     → branch 0
  // Tab 1 Explore  → branch 3 (CoursePage course grid)
  // Tab 2 Library  → branch 5
  // Tab 3 Habit    → branch 4
  // Tab 4 Community→ branch 6
  // The course-roadmap branch (1) is not a bottom tab and is NEVER the target
  // of a tab tap — tapping Khám phá always opens the Explore browse grid
  // (branch 3), even if a roadmap was left open on a previous visit to that
  // tab. The roadmap is reached only by tapping a specific course (Home "Jump
  // back in"/Recommended, Explore grid, Library) — see its own "back to
  // Explore"/"back to Home" handling in course_roadmap_page.dart.
  //
  // Profile (branch 2) lost its tab to Library (design `5b · Library`): it is
  // reached from the Home header avatar instead, and keeps the nav bar so the
  // reader can leave for any tab — see [_branchToVisual].
  static const _tabToBranch = [0, 3, 5, 4, 6];

  // Visual tab each branch lights up when the shell arrives there from
  // outside a tab tap (e.g. entering the roadmap by tapping a course). The
  // roadmap (branch 1) has no tab of its own, so — purely for highlighting —
  // it shares the Khám phá slot (visual 1) with the course grid (branch 3).
  //
  // Profile (branch 2) maps to -1: it has no tab at all, so the bar renders with
  // NOTHING lit rather than borrowing another tab's highlight and claiming the
  // reader is somewhere they aren't.
  static const _branchToVisual = {0: 0, 1: 1, 2: -1, 3: 1, 4: 3, 5: 2, 6: 4};

  int _visualIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchIndex = context.read<PageCubit>().state.currentIndex;
    _visualIndex = _branchToVisual[branchIndex] ?? 0;
  }

  void _onTabTap(int visualIndex) {
    AppHaptic.select();
    setState(() => _visualIndex = visualIndex);
    context.read<PageCubit>().handleShellRouteNavigation(_tabToBranch[visualIndex], widget.navigationShell);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the highlighted tab in sync with the branch the shell is actually
    // showing. Navigations via go() (e.g. splash → CourseRoute for guests with
    // no roadmap) switch the shell branch without going through _onTabTap,
    // which would otherwise leave the wrong tab lit (e.g. "Home" highlighted
    // while the Explore grid is on screen).
    final activeBranch = widget.navigationShell.currentIndex;
    final expectedVisual = _branchToVisual[activeBranch] ?? _visualIndex;
    if (expectedVisual != _visualIndex) {
      _visualIndex = expectedVisual;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Primary tabs (Home/Explore/Library/Habit) all sit on light
      // backgrounds → DARK status-bar icons (clock/battery/wifi). Set it on the
      // shell so it sticks even when arriving from a screen that left a
      // light-icon AnnotatedRegion active (splash/onboard); full-screen
      // sub-routes (lesson/roleplay/video) override with their own region.
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: BlocListener<PageCubit, PageState>(
        listenWhen: (prev, curr) => prev.currentIndex != curr.currentIndex,
        listener: (context, state) {
          final visual = _branchToVisual[state.currentIndex] ?? 0;
          if (visual != _visualIndex) {
            setState(() => _visualIndex = visual);
          }
        },
        child: Stack(
          children: [
            // Full-screen content — each page handles its own safe-area bottom
            // padding (or ignores it if it has a floating CTA of its own).
            // Wrapped in ThemedBackground so the user's chosen study background
            // (study_theme) paints behind every tab that opts in with a
            // transparent Scaffold; seamless across tab switches (single host).
            // StreakPopupHost wraps the shell (not Home) so the daily
            // time counter keeps running across every tab. GiftPopupHost is on
            // the shell for the same reason, plus one of its own: it watches for
            // app RESUME, which is how the days 1-7 gift popup reaches a reader
            // who left MeUp in the background rather than cold-starting it.
            // ImportDonePopupHost joins them for both reasons at once: it must
            // survive tab switches, AND it watches RESUME — an import keeps
            // running server-side while the app is suspended, so coming back is
            // the moment to check whether the lesson is ready.
            Positioned.fill(
              // WeekRecapPopupHost is outermost, and is the only one of these
              // that raises a full dialog on a cold start. It shares
              // AppOpenModalGate with the Home promo popup so the two can never
              // stack into a card on a card.
              child: WeekRecapPopupHost(
                child: ImportDonePopupHost(
                  // WinBackHost sits here for the same reason as its
                  // neighbours: the paywall that arms it is gone before its
                  // delay elapses, so the opener has to outlive it.
                  child: WinBackHost(
                    child: GiftPopupHost(
                      child: StreakPopupHost(
                        child: ThemedBackground(child: widget.navigationShell),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // The minimised import, above the nav bar. Shown on sub-routes too:
            // a run the reader minimised is still running while they read
            // something else, and going quiet about it is what the toast exists
            // to stop.
            BlocSelector<PageCubit, PageState, ({bool isPrimary, bool shownInline})>(
              selector: (state) => (
                isPrimary: state.isPrimaryRoute,
                // My Creations carries the same run as a row in its own list, so
                // a toast there would repeat the screen back to itself — and sit
                // on top of that screen's create bar while doing it. The
                // generating screen IS the run, full-size — a minimised copy of
                // the thing you are looking at ("cục loading ở dưới không cần
                // hiện ở màn này", 2026-08-12).
                shownInline: state.currentRouteName == RouteNamed.myLessons || state.currentRouteName == RouteNamed.importGenerating,
              ),
              builder: (context, placement) => placement.shownInline
                  ? const SizedBox.shrink()
                  : ImportProgressToast(
                      bottomInset: placement.isPrimary ? floatingNavBarHeight(context) + 10.h : MediaQuery.paddingOf(context).bottom + 18.h,
                    ),
            ),
            // The AI Coach bubble. A sibling of the import toast rather than a
            // member of the popup-host chain above, and deliberately so: it
            // never opens itself, so it never has to queue behind the week
            // recap, the gift and the streak toast for AppOpenModalGate. It
            // decides for itself which tabs it belongs on (Home and Habit) and
            // renders nothing everywhere else.
            CoachBubbleHost(bottomInset: floatingNavBarHeight(context) + 12.h),
            // Floating pill navbar — hidden on sub-routes (lesson, roleplay…)
            BlocSelector<PageCubit, PageState, bool>(
              selector: (state) => state.isPrimaryRoute,
              builder: (context, isPrimary) {
                if (!isPrimary) return const SizedBox.shrink();
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _FloatingNavBar(
                    selectedIndex: _visualIndex,
                    onTap: _onTabTap,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// [_FloatingNavBar]'s own content height (top padding + row height) — the
/// part that's fixed regardless of device. Combine with the device's bottom
/// safe-area inset (via [floatingNavBarHeight]) to get the bar's true total
/// height: that inset varies a lot — 3-button nav devices reserve far more
/// space than gesture-nav ones — so anything floating above the nav bar must
/// clear the actual total, not a single guessed constant.
const double _kFloatingNavBarContentHeight = 8 + 56;

/// Total rendered height of the shell's floating pill nav bar on this device:
/// its fixed content height plus the bottom safe-area inset the bar pads
/// itself with. Other floating elements (reminder cards, CTAs) must clear
/// this — a flat guess clips on devices with a taller inset (3-button nav)
/// even though it looks fine on gesture-nav ones. Must stay in sync with
/// [_FloatingNavBar]'s own padding.
double floatingNavBarHeight(BuildContext context) {
  // viewPaddingOf, not paddingOf: the latter is the current SafeArea/keyboard-
  // adjusted padding and can under-report the true system-bar inset depending
  // on ancestor widgets; viewPaddingOf is the raw, stable device safe-area
  // inset used everywhere else in the app for this exact "clear the system
  // bottom bar" need (see e.g. video_lesson_notes_sheet_list.dart).
  return MediaQuery.viewPaddingOf(context).bottom + _kFloatingNavBarContentHeight.h;
}

/// Gradient-shroud wrapper + blurred pill container.
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Must match floatingNavBarHeight's source exactly (viewPaddingOf, not
    // paddingOf) or the two silently drift apart on devices where they'd
    // otherwise disagree.
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    // Solid white bar filling the full width to the bottom of the screen, with
    // a lightly-rounded top edge + a thin top shadow as the only "border".
    // No gradient shroud (no gray band).
    return Container(
      decoration: BoxDecoration(
        color: AppCustomColor.backgroundWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        // Thin, crisp top edge only — no gray haze band.
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.r,
            offset: Offset(0, -1.h),
          ),
        ],
      ),
      // Sit lower: keep only the device safe-area inset (don't scale it with
      // .h, and drop the extra +8 that pushed the bar up).
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, bottomInset),
      child: Semantics(
        label: 'Bottom navigation',
        explicitChildNodes: true,
        child: SizedBox(
          height: 56.h,
          child: Row(
            children: List.generate(
              5,
              (i) => _NavItem(
                index: i,
                selectedIndex: selectedIndex,
                onTap: onTap,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Single tab cell: icon-only when inactive, icon + label when active.
class _NavItem extends StatelessWidget {
  final int index;
  final int selectedIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.index,
    required this.selectedIndex,
    required this.onTap,
  });

  static final _iconPaths = [
    AppAsset.svg.common.navHome,
    AppAsset.svg.common.navExplore,
    AppAsset.svg.common.navCourse,
    AppAsset.svg.common.navGrowth,
    AppAsset.svg.common.navCommunity,
  ];

  static const _navColor = Color(0xFF110751);

  String _label(BuildContext context) {
    final l10n = context.l10n.home;
    switch (index) {
      case 0:
        return l10n.homeHomeButton;
      case 1:
        return l10n.homeExploreButton;
      case 2:
        return context.l10n.library.navLabel;
      case 3:
        return context.l10n.habit.navLabel;
      case 4:
        return context.l10n.community.navLabel;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    final label = _label(context);
    // Active = Text/Brand navy; inactive = Icon/Disable (#AAB8CD) per Figma.
    final tint = isActive ? _navColor : AppCustomColor.textQuaternary;
    // Two icons are two-tone — a coloured body plus a WHITE inner detail: the
    // Habit sprout (leaves + highlight) and the Confession bubble (bubble + its
    // three dots). A srcIn colorFilter would repaint that white too, flattening
    // each into a blob, so tint the body via currentColor and let the white
    // stay white (Figma nav bar 11634:15439; design `13 · Confession`
    // nav-confession-on/off). The other three are single-tone.
    final isTwoTone = index == 3 || index == 4;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isActive,
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                _iconPaths[index],
                width: 24.w,
                height: 24.w,
                theme: isTwoTone ? SvgTheme(currentColor: tint) : const SvgTheme(),
                colorFilter: isTwoTone ? null : ColorFilter.mode(tint, BlendMode.srcIn),
              ),
              if (isActive) ...[
                SizedBox(height: 2.h),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: _navColor,
                    height: 1.75,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
