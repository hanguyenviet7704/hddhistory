part of '../../course.dart';

class CoursePage extends StatefulWidget {
  final int? selectedTabIndex;
  const CoursePage({super.key, this.selectedTabIndex});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  @override
  void initState() {
    super.initState();
    _initializeSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenPaywallAutoOpen());
  }

  void _initializeSelection() {
    final cubit = context.read<CourseCubit>()
      ..selectTab(1)
      ..clearSearch();
    // Onboarding / auth deep-links pass a skillset index to land on; everything
    // else opens in the default "all courses / out menu" state.
    final deepLinkIndex = widget.selectedTabIndex;
    if (deepLinkIndex != null && deepLinkIndex >= 0) {
      cubit.jumpToSkillset(deepLinkIndex);
    } else {
      cubit.resetExploreToAll();
    }
  }

  Future<void> _tryOpenPaywallAutoOpen() async {
    if (!mounted) return;
    final userState = context.read<UserCubit>().state;
    final user = userState.user;
    final profileCubit = context.read<ProfileCubit>();
    final didPrepare = await context.read<IapCubit>().prepareAutoOpenPaywall(
      userId: user.id,
      accessToken: userState.accessToken,
      hasCompletedOnboarding: !userState.isUserPassOnboarding,
      isPremium: profileCubit.state.user.isPremium,
      refreshPremiumStatus: () async {
        if (profileCubit.state.user.id.isEmpty && user.id.isNotEmpty) {
          profileCubit.setUser(user);
        }
        await profileCubit.loadUserIapSubscriptions();
        if (profileCubit.state.status == ProfileStatus.failure) return null;
        return profileCubit.state.user.isPremium;
      },
    );
    if (!mounted || !didPrepare) return;
    await const PaywallRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('course-page'),
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            16.verticalSpace,
            const CourseHeader(),
            12.verticalSpace,
            BlocBuilder<CourseCubit, CourseState>(
              buildWhen: (prev, curr) => prev.isSearchActive != curr.isSearchActive,
              builder: (context, state) {
                if (state.isSearchActive) {
                  return const Expanded(child: CourseSearchView());
                }
                return Expanded(
                  child: Column(
                    children: [
                      const _CourseFilterTabBar(),
                      12.verticalSpace,
                      const Expanded(child: AllCourseTab()),
                    ],
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

// ---------------------------------------------------------------------------
// _ExploreChipBar — new Figma-spec chip bar for the Explore (course) page.
// Chip order: [My courses] [All] [skillset 0] [skillset 1] …
// Does NOT touch FilterTabBar (still used by change_course_page).
// ---------------------------------------------------------------------------

class _CourseFilterTabBar extends StatelessWidget {
  const _CourseFilterTabBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets,
      builder: (context, homeState) {
        return BlocBuilder<CourseCubit, CourseState>(
          buildWhen: (prev, curr) =>
              prev.exploreMode != curr.exploreMode ||
              prev.activeSkillsetIndex != curr.activeSkillsetIndex,
          builder: (context, courseState) {
            // selectedIndex mapping:
            //  0 → My courses (exploreMode == myCourses)
            //  1+ → skillset[i-1] (when scrolled/jumped to that skillset)
            //  -1 → no chip highlighted ("all" / out-menu, before any scroll)
            final selectedIndex = courseState.exploreMode == CourseExploreMode.myCourses
                ? 0
                : courseState.activeSkillsetIndex >= 0
                    ? courseState.activeSkillsetIndex + 1
                    : -1;

            return Semantics(
              label: context.l10n.allcourse.allcourseExploreSkillsets,
              child: _ExploreChipBar(
                key: const Key('course-filter-tab-bar'),
                skillsets: homeState.skillsets,
                selectedIndex: selectedIndex,
                myCoursesLabel: context.l10n.allcourse.allcourseMyCourse,
                onChipTap: (i) {
                  final cubit = context.read<CourseCubit>();
                  if (i == 0) {
                    cubit.showMyCourses();
                  } else {
                    cubit.jumpToSkillset(i - 1);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ExploreChipBar — stateful so it owns GlobalKeys + ScrollController for
// autoScrollToSelected (mirrors FilterTabBar's ensureVisible approach).
// ---------------------------------------------------------------------------

class _ExploreChipBar extends StatefulWidget {
  const _ExploreChipBar({
    super.key,
    required this.skillsets,
    required this.selectedIndex,
    required this.myCoursesLabel,
    required this.onChipTap,
  });

  final List<SkillsetEntity> skillsets;
  final int selectedIndex;
  final String myCoursesLabel;
  final ValueChanged<int> onChipTap;

  @override
  State<_ExploreChipBar> createState() => _ExploreChipBarState();
}

class _ExploreChipBarState extends State<_ExploreChipBar> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _chipKeys = const [];

  int get _chipCount => 1 + widget.skillsets.length; // My courses + skillsets

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  void _syncKeys() {
    if (_chipKeys.length != _chipCount) {
      _chipKeys = List.generate(_chipCount, (_) => GlobalKey());
    }
  }

  @override
  void didUpdateWidget(covariant _ExploreChipBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncKeys();
    if (widget.selectedIndex != oldWidget.selectedIndex &&
        widget.selectedIndex >= 0 &&
        widget.selectedIndex < _chipKeys.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    final idx = widget.selectedIndex;
    if (idx < 0 || idx >= _chipKeys.length) return;
    final ctx = _chipKeys[idx].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncKeys();
    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: _chipCount,
        separatorBuilder: (context, index) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ExploreChip(
              chipKey: _chipKeys[index],
              label: widget.myCoursesLabel,
              icon: null,
              isSelected: widget.selectedIndex == 0,
              onTap: () => widget.onChipTap(0),
            );
          }
          final skillset = widget.skillsets[index - 1];
          return _ExploreChip(
            chipKey: _chipKeys[index],
            label: skillset.title.text,
            icon: skillset.image.isNotEmpty
                ? _SkillsetIcon(imageUrl: skillset.image)
                : null,
            isSelected: widget.selectedIndex == index,
            onTap: () => widget.onChipTap(index),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ExploreChip — a single chip in the bar.
// ---------------------------------------------------------------------------

class _ExploreChip extends StatelessWidget {
  const _ExploreChip({
    required this.chipKey,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final GlobalKey chipKey;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// Widget rendered inside the 32×32 icon box. Null for "My courses".
  final Widget? icon;

  static const double _iconBoxSize = 32;
  static const double _radius = 52;

  EdgeInsetsGeometry get _padding {
    if (icon == null) {
      // No icon (My courses): symmetric horizontal
      return EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h);
    }
    // Chips with icon: pl 8, pr 12
    return EdgeInsetsDirectional.only(
      start: 8.w,
      end: 12.w,
      top: 4.h,
      bottom: 4.h,
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isSelected ? AppCustomColor.backgroundBrandSoft : AppCustomColor.backgroundGray;
    final labelColor =
        isSelected ? AppCustomColor.streakActive : AppCustomColor.streakTextMuted;
    final fontWeight = isSelected ? FontWeight.w700 : FontWeight.w600;

    return Semantics(
      key: chipKey,
      label: label,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: _padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_radius.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                SizedBox(
                  width: _iconBoxSize.w,
                  height: _iconBoxSize.w,
                  child: icon,
                ),
                SizedBox(width: 6.w),
              ],
              Text(
                label,
                style: AppStyle.text14.copyWith(
                  color: labelColor,
                  fontWeight: fontWeight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SkillsetIcon — network image for a skillset chip icon.
// ---------------------------------------------------------------------------

class _SkillsetIcon extends StatelessWidget {
  const _SkillsetIcon({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CacheNetworkGraphic(
        url: imageUrl,
        width: 24.w,
        height: 24.w,
        fit: BoxFit.contain,
      ),
    );
  }
}
