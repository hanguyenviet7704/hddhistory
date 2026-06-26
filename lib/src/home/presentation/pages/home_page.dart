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
          body: SafeBody(
            child: Stack(
              children: [
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
                        // Header
                        const HomeHeaderWidget(),

                        // Quote of the day
                        20.verticalSpace,
                        const HomeQuoteCard(),

                        // Courses section
                        BlocBuilder<ProgressCubit, ProgressState>(
                          builder: (context, state) {
                            if (state.myCourses.isEmpty) return const SizedBox.shrink();
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                4.verticalSpace,
                                AppText(
                                  context.l10n.home.continueLearning,
                                  enableFitScaleDown: true,
                                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                                  style: AppStyle.textBold18.copyWith(color: AppCustomColor.textPrimary),
                                ),
                                12.verticalSpace,
                                // Course cards horizontal scroll
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                                  child: Row(
                                    children: state.myCourses
                                        .map(
                                          (course) => CourseCardWidget(
                                            course: course.withSkillset,
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                                20.verticalSpace,
                              ],
                            );
                          },
                        ),

                        // Got ideas banner
                        20.verticalSpace,
                        GotIdeasBanner(
                          onTap: () => const DataCollectFeedbackRoute().push(context),
                        ),
                        20.verticalSpace,

                        // Recommended courses section header
                        SectionHeaderWidget(
                          title: context.l10n.home.homeRecommendCourse,
                          actionText: context.l10n.home.homeRecommendedSeeAll,
                          onActionTap: () {
                            context.read<CourseCubit>().setAllCourseSource('home_recommend_view');
                            CourseRoute().push(context);
                          },
                        ),
                        16.verticalSpace,

                        // Recommended courses horizontal scroll
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
                ),
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
