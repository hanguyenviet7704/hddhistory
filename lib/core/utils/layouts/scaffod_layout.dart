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
  // Maps visual tab index (0-4) to shell branch index (0-2).
  // Tab 0 Home   → branch 0
  // Tab 1 Course → branch 1
  // Tab 2 Explore→ branch 1 (same shell, future sub-route)
  // Tab 3 Growth → branch 0 (same shell, future sub-route)
  // Tab 4 Profile→ branch 2
  static const _tabToBranch = [0, 1, 1, 0, 2];

  // Default visual index for each branch when navigating from outside.
  static const _branchToVisual = {0: 0, 1: 1, 2: 4};

  int _visualIndex = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final branchIndex = context.read<PageCubit>().state.currentIndex;
    _visualIndex = _branchToVisual[branchIndex] ?? 0;
  }

  void _onTabTap(int visualIndex) {
    final branchIndex = _tabToBranch[visualIndex];
    setState(() => _visualIndex = visualIndex);
    context.read<PageCubit>().handleShellRouteNavigation(branchIndex, widget.navigationShell);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
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
          Positioned.fill(child: widget.navigationShell),
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
    );
  }
}

/// Gradient-shroud wrapper + blurred pill container.
class _FloatingNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onTap;

  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      // Gradient fade from transparent → white so content below scrolls
      // beneath this bar without a hard clip edge.
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.white],
          stops: [0.0, 0.35],
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, (16 + bottomInset).h),
      child: Semantics(
        label: 'Bottom navigation',
        explicitChildNodes: true,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50.r),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              height: 56.h,
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(50.r),
              ),
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
    AppAsset.svg.common.navCourse,
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
        return l10n.homeCourseButton;
      case 2:
        return l10n.homeExploreButton;
      case 3:
        return l10n.homeGrowthButton;
      case 4:
        return l10n.homeSettingButton;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = index == selectedIndex;
    final label = _label(context);

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
                colorFilter: ColorFilter.mode(
                  isActive
                      ? _navColor
                      : _navColor.withValues(alpha: 0.3),
                  BlendMode.srcIn,
                ),
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
