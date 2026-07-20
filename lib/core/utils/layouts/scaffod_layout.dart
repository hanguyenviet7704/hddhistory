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
  // Maps visual tab index (0-3) to shell branch index.
  // Tab 0 Home   → branch 0
  // Tab 1 Explore→ branch 3 (CoursePage course grid)
  // Tab 2 Habit  → branch 4
  // Tab 3 Profile→ branch 2
  // The course-roadmap branch (1) is no longer a bottom tab — it's reached by
  // tapping a course (Home "Jump back in"/Recommended, Explore) or via
  // Profile › Library › My Course.
  static const _tabToBranch = [0, 3, 4, 2];

  // Default visual index for each branch when navigating from outside. Branch 1
  // (course roadmap) has no tab of its own → light the Explore tab, since
  // courses are browsed/opened from Explore (and Home's "Jump back in").
  static const _branchToVisual = {0: 0, 1: 1, 2: 3, 3: 1, 4: 2};

  int _visualIndex = 0;

  // Visual tab 1 (Khám phá) is shared by TWO shell branches: the course-roadmap
  // (branch 1) and the course-list grid (branch 3). Remember whichever the user
  // was last in so tapping that tab RETURNS them there — e.g. resume the roadmap
  // after a detour to another tab, instead of always snapping back to the grid.
  // Browsing is never stranded: the roadmap's own "back to Explore" button and
  // Home's course entries still switch to the grid (which updates this too).
  int _courseSlotBranch = 3;

  // Branch the given visual tab should open. All tabs are fixed except the
  // shared Khám phá slot, which follows the last-used course branch above.
  int _branchForVisual(int visualIndex) => visualIndex == 1 ? _courseSlotBranch : _tabToBranch[visualIndex];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchIndex = context.read<PageCubit>().state.currentIndex;
    if (branchIndex == 1 || branchIndex == 3) _courseSlotBranch = branchIndex;
    _visualIndex = _branchToVisual[branchIndex] ?? 0;
  }

  void _onTabTap(int visualIndex) {
    AppHaptic.select();
    final branchIndex = _branchForVisual(visualIndex);
    setState(() => _visualIndex = visualIndex);
    context.read<PageCubit>().handleShellRouteNavigation(branchIndex, widget.navigationShell);
  }

  @override
  Widget build(BuildContext context) {
    // Keep the highlighted tab in sync with the branch the shell is actually
    // showing. Navigations via go() (e.g. splash → CourseRoute for guests with
    // no roadmap) switch the shell branch without going through _onTabTap,
    // which would otherwise leave the wrong tab lit (e.g. "Home" highlighted
    // while the Explore grid is on screen).
    final activeBranch = widget.navigationShell.currentIndex;
    // Remember which of the shared course-slot branches (roadmap=1 / grid=3) is
    // live, so the Khám phá tab can return to it after a detour to another tab.
    if (activeBranch == 1 || activeBranch == 3) {
      _courseSlotBranch = activeBranch;
    }
    if (_branchForVisual(_visualIndex) != activeBranch) {
      _visualIndex = _branchToVisual[activeBranch] ?? _visualIndex;
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Primary tabs (Home/Explore/Habit/Profile) all sit on light
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
            Positioned.fill(child: ThemedBackground(child: widget.navigationShell)),
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
              4,
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
    AppAsset.svg.common.navGrowth,
    AppAsset.svg.common.navProfile,
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
        return context.l10n.habit.navLabel;
      case 3:
        return l10n.homeSettingButton;
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
    // The Habit (growth) sprout is two-tone — coloured leaves + a WHITE inner
    // highlight. A srcIn colorFilter would repaint that white too, flattening
    // it into a blob, so tint it via currentColor (leaves) and let the white
    // stay white (Figma nav bar 11634:15439). Other icons are single-tone.
    final isTwoToneSprout = index == 2;

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
                theme: isTwoToneSprout ? SvgTheme(currentColor: tint) : const SvgTheme(),
                colorFilter: isTwoToneSprout ? null : ColorFilter.mode(tint, BlendMode.srcIn),
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
