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
    HomeState homeState = context.read<HomeCubit>().state;
    _initialCategoryIndex = widget.selectedTabIndex ?? homeState.selectedSkillsetIndex;
    context.read<CourseCubit>().selectTab(1);
    context.read<CourseCubit>().clearSearch();
  }

  void _trackMyCourseView() {
    AppService.instance.appTrackingService.trackCourseSelectMyCourseView(source: 'course_selection');
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
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: BlocListener<CourseCubit, CourseState>(
          listenWhen: (previous, current) => previous.selectedTabIndex != current.selectedTabIndex && current.selectedTabIndex == 0,
          listener: (context, state) => _trackMyCourseView(),
          child: Column(
            children: [
              const CourseHeader(),
              Expanded(
                child: BlocBuilder<CourseCubit, CourseState>(
                  buildWhen: (previous, current) => previous.selectedTabIndex != current.selectedTabIndex,
                  builder: (context, state) {
                    final selectedIndex = state.selectedTabIndex == 1 ? 1 : 0;
                    return IndexedStack(
                      index: selectedIndex,
                      children: [
                        const MyCourseTab(),
                        AllCourseTab(
                          initialCategoryIndex: _initialCategoryIndex,
                          isVisible: selectedIndex == 1,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
