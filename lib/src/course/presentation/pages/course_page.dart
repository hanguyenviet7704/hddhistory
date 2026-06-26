part of '../../course.dart';

class CoursePage extends StatefulWidget {
  final int? selectedTabIndex;
  const CoursePage({super.key, this.selectedTabIndex});

  @override
  State<CoursePage> createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {
  late final int _initialCategoryIndex;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryOpenPaywallAutoOpen());
  }

  void _initializeSelection() {
    final homeState = context.read<HomeCubit>().state;
    _initialCategoryIndex = widget.selectedTabIndex ?? homeState.selectedSkillsetIndex;
    context.read<CourseCubit>()
      ..selectTab(1)
      ..clearSearch()
      ..selectCategory(_initialCategoryIndex);
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

class _CourseFilterTabBar extends StatelessWidget {
  const _CourseFilterTabBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, curr) => prev.skillsets != curr.skillsets,
      builder: (context, homeState) {
        final skillsets = homeState.skillsets;
        final allLabel = context.l10n.allcourse.allcourseAllCourses;
        final tabs = [allLabel, ...skillsets.map((s) => s.title.text)];

        return BlocBuilder<CourseCubit, CourseState>(
          buildWhen: (prev, curr) => prev.selectedCategoryIndex != curr.selectedCategoryIndex,
          builder: (context, courseState) {
            final tabIndex = _categoryIndexToTabIndex(courseState.selectedCategoryIndex, skillsets.length);
            return Semantics(
              label: context.l10n.allcourse.allcourseExploreSkillsets,
              child: FilterTabBar(
                key: const Key('course-filter-tab-bar'),
                tabs: tabs,
                selectedIndex: tabIndex,
                onTabSelected: (i) {
                  final categoryIndex = i == 0 ? -1 : i - 1;
                  context.read<CourseCubit>().selectCategory(categoryIndex);
                },
              ),
            );
          },
        );
      },
    );
  }

  int _categoryIndexToTabIndex(int categoryIndex, int skillsetCount) {
    if (categoryIndex < 0) return 0;
    return (categoryIndex + 1).clamp(0, skillsetCount);
  }
}
