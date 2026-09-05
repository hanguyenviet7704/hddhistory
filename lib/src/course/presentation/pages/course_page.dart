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
    // The Explore grid renders HomeCubit's skillsets — recover from a
    // failed/skipped first load (e.g. transient failure right after a fresh
    // install) instead of showing an empty grid until app restart. No-op
    // when data is present.
    unawaited(AppDI.injector.get<HomeCubit>().ensureHomeDataLoaded());
    // The import button on this screen is drawn from the quota's `enabled`
    // flag, and nothing else on Explore fetches it. One silent GET here is what
    // lets the button disappear when the feature is switched off, instead of
    // waiting for the reader to tap it and be refused.
    unawaited(AppDI.injector.get<LearningImportCubit>().loadQuota());
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
      // Transparent only when a custom study background is active.
      backgroundColor: studyThemeScaffoldColor(context, AppCustomColor.backgroundWhite),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                16.verticalSpace,
                BlocBuilder<CourseCubit, CourseState>(
                  buildWhen: (prev, curr) => prev.isSearchActive != curr.isSearchActive,
                  builder: (context, state) {
                    // Searching pins the field: the results below it change under
                    // every keystroke, and a field that scrolls away mid-typing
                    // is a field you cannot correct.
                    if (state.isSearchActive) {
                      return const Expanded(
                        child: Column(
                          children: [
                            CourseHeader(),
                            SizedBox(height: 12),
                            Expanded(child: CourseSearchView()),
                          ],
                        ),
                      );
                    }

                    // Browsing scrolls the whole page — the search field and the
                    // import board ride at the top of the list itself, and the
                    // skillset chip strip is gone (owner, 2026-09-05: "bỏ thanh
                    // scroll ngang… cho cuộn cả thanh tìm kiếm và phần tạo bài
                    // học"). The sections' own headings say where you are.
                    return const Expanded(child: AllCourseTab());
                  },
                ),
              ],
            ),
          ),
          // Above the tab's own content and outside the SafeArea column so the
          // scrim covers the whole screen, status bar included.
          const ImportFocusGuide(),
        ],
      ),
    );
  }
}
