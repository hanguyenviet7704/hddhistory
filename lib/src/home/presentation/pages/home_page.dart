part of '../../home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with _HomeInAppSurveyMixin, _HomeDailyWarmUpMixin {
  void _trackHomeScrView() {
    AppService.instance.appTrackingService.trackHomeScrView();
  }

  Future<void> _prefetchLearningStreak() async {
    final userId = context.read<UserCubit>().state.user.id;
    await context.read<LearningStreakCubit>().loadUserLearningStreak(
      triggerSource: LearningStreakTriggerSource.homeChip,
      requestedUserId: userId,
      timeout: const Duration(seconds: 2),
      emitLoading: false,
      allowSafeDefaultOnFailure: true,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _trackHomeScrView();
      await _prefetchLearningStreak();
      final didOpenPaywall = await _tryOpenPaywallAutoOpen();
      if (didOpenPaywall) return;
      final didOpenWarmUp = await _tryOpenDailyWarmUp();
      if (!didOpenWarmUp) {
        await _loadInAppSurveyConfig();
        if (mounted) _handleSurveyStateChanged(context.read<InAppSurveyCubit>().state);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 0) {
          _trackHomeScrView();
        }
      },
      child: BlocListener<InAppSurveyCubit, InAppSurveyState>(
        listenWhen: (previous, current) => previous.isEntryVisible != current.isEntryVisible,
        listener: (context, state) => _handleSurveyStateChanged(state),
        child: Scaffold(
          key: const Key('home-page'),
          // Extend gradient behind status bar
          backgroundColor: const Color(0xFFBEBCF6),
          body: SafeBody(
            child: Stack(
              children: [
                // ── Gradient background extends behind status bar ─────────
                Container(
                  color: const Color(0xFFBEBCF6),
                ),

                RefreshIndicator(
                  onRefresh: () async {
                    context.read<HomeCubit>().initializeData(isInit: true);
                    await _prefetchLearningStreak();
                    final didOpenPaywall = await _tryOpenPaywallAutoOpen();
                    if (didOpenPaywall) return;
                    final didOpenWarmUp = await _tryOpenDailyWarmUp();
                    if (!didOpenWarmUp) await _loadInAppSurveyConfig();
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Zone 1: Purple gradient header ─────────────────
                        const HomeHeaderWidget(),

                        // ── Zone 2: White content area (rounded top) ───────
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppCustomColor.backgroundWhite,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20.r),
                              topRight: Radius.circular(20.r),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              24.verticalSpace,

                              // ── Continue learning ──────────────────────
                              BlocBuilder<ProgressCubit, ProgressState>(
                                builder: (context, state) {
                                  if (state.myCourses.isEmpty) return const SizedBox.shrink();
                                  return _ContinueLearningSection(courses: state.myCourses);
                                },
                              ),

                              // ── Got ideas? banner ──────────────────────
                              20.verticalSpace,
                              GotIdeasBanner(
                                onTap: () => const DataCollectFeedbackRoute().push(context),
                              ),
                              20.verticalSpace,

                              // ── Recommended courses ────────────────────
                              SectionHeaderWidget(
                                title: context.l10n.home.homeRecommendCourse,
                                actionText: context.l10n.home.homeRecommendedSeeAll,
                                onActionTap: () {
                                  context.read<CourseCubit>().setAllCourseSource('home_recommend_view');
                                  CourseRoute().push(context);
                                },
                              ),
                              16.verticalSpace,

                              BlocSelector<HomeCubit, HomeState, List<SuggestedCourseEntity>>(
                                selector: (state) => state.suggestedCourses,
                                builder: (context, suggestedCourses) {
                                  if (suggestedCourses.isEmpty) return const SizedBox.shrink();

                                  final cards = suggestedCourses
                                      .map(
                                        (s) => CourseEntity(
                                          id: s.id,
                                          title: s.title,
                                          description: s.description,
                                          image: s.image,
                                          skillsetId: s.skillsetId,
                                          numberOfLesson: s.numberOfLesson,
                                        ).withSkillset,
                                      )
                                      .toList();

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                                    child: Row(
                                      children: cards
                                          .map((course) => CourseCardWidget(course: course))
                                          .toList(),
                                    ),
                                  );
                                },
                              ),

                              // Bottom padding
                              96.verticalSpace,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Floating InAppSurvey pill ──────────────────────────────
                BlocSelector<InAppSurveyCubit, InAppSurveyState, bool>(
                  selector: (state) => state.isEntryVisible,
                  builder: (context, isEntryVisible) {
                    if (!isEntryVisible) return const SizedBox.shrink();

                    return Positioned(
                      left: 20.w,
                      right: 20.w,
                      bottom: 20.h,
                      child: Center(
                        child: InAppSurveyEntryPill(
                          onTap: _openInAppSurveyDialog,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _tryOpenPaywallAutoOpen() async {
    if (!mounted) return false;
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
    if (!mounted || !didPrepare) return false;
    await const PaywallRoute().push(context);
    return true;
  }
}

/// "Continue learning" section: heading + swipeable [PageView] of large portrait
/// course cards + animated page-dot indicator.
class _ContinueLearningSection extends StatefulWidget {
  final List<CourseEntity> courses;

  const _ContinueLearningSection({required this.courses});

  @override
  State<_ContinueLearningSection> createState() => _ContinueLearningSectionState();
}

class _ContinueLearningSectionState extends State<_ContinueLearningSection> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      // Show a sliver of the next card to signal swipeability
      viewportFraction: 0.92,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section heading
        AppText(
          context.l10n.home.continueLearning,
          enableFitScaleDown: true,
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          style: AppStyle.textBold20.copyWith(color: AppCustomColor.textPrimary),
        ),
        12.verticalSpace,

        // Card PageView — fixed height matching the portrait card
        SizedBox(
          height: 380.h,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.courses.length,
            itemBuilder: (ctx, i) {
              return Padding(
                // Horizontal gutter between cards and from screen edge
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: HomeLargePortraitCourseCard(
                  course: widget.courses[i].withSkillset,
                ),
              );
            },
          ),
        ),

        // Page-dot indicator — only rendered when more than one card
        if (widget.courses.length > 1) ...[
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.courses.length, (i) {
              final isActive = i == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.symmetric(horizontal: 3.w),
                width: isActive ? 36.w : 12.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppCustomColor.textPrimary
                      : AppCustomColor.textPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(30.r),
                ),
              );
            }),
          ),
        ] else
          12.verticalSpace,
      ],
    );
  }
}
