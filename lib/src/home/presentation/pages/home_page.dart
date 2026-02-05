part of '../../home.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  void _loadIapProducts(BuildContext context) {
    // AppDI.injector.get<UserCubit>()
    //   ..setIsFirstTimeUserChooseCourse(true)
    //   ..setIsFirstTimeLessonNavigationGuide(true);
    List<IapProductEntity> iapProducts = context.read<IapCubit>().state.iapProducts;
    if (iapProducts.isNotEmpty) return;
    context.read<IapCubit>().loadIapProducts();
  }

  void _trackHomeScrView() {
    AppService.instance.appTrackingService.trackHomeScrView();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _trackHomeScrView());
  }

  @override
  Widget build(BuildContext context) {
    _loadIapProducts(context);
    return BlocListener<PageCubit, PageState>(
      listenWhen: (previous, current) => previous.currentIndex != current.currentIndex,
      listener: (context, state) {
        if (state.currentIndex == 0) {
          _trackHomeScrView();
        }
      },
      child: Scaffold(
        body: SafeBody(
          child: RefreshIndicator(
            onRefresh: () async => context.read<HomeCubit>().initializeData(isInit: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  const HomeHeaderWidget(),

                  // Courses section
                  BlocBuilder<ProgressCubit, ProgressState>(
                    builder: (context, state) {
                      if (state.myCourses.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          4.verticalSpace,
                          AppText(
                            context.text.home.continueLearning,
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

                  // Skillsets section
                  SectionHeaderWidget(
                    title: context.text.home.homeRecommendCourse,
                    actionText: context.text.home.homeSeeAllLearningListButton,
                    onActionTap: () {
                      context.read<CourseCubit>().setAllCourseSource('home_skill_view');
                      CourseRoute().push(context);
                    },
                  ),
                  16.verticalSpace,

                  // Skillsets grid
                  BlocSelector<HomeCubit, HomeState, List<SkillsetEntity>>(
                    selector: (state) => state.skillsets,
                    builder: (context, skillsets) {
                      return GridView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12.w,
                          mainAxisSpacing: 12.h,
                          childAspectRatio: 161.w / 234.h,
                        ),
                        itemCount: skillsets.length,
                        itemBuilder: (context, index) {
                          final skillset = skillsets[index];
                          return SkillsetCardWidget(
                            skillset: skillset,
                            onTap: () {
                              context.read<CourseCubit>().setAllCourseSource('home_skill_view');
                              AppService.instance.appTrackingService.trackHomeSkillClick(skillset);
                              CourseRoute(selectedTabIndex: index).push(context);
                            },
                          );
                        },
                      );
                    },
                  ),

                  // Loading indicator for skillsets
                  BlocSelector<HomeCubit, HomeState, bool>(
                    selector: (state) => state.status == HomeStatus.loading,
                    builder: (context, isLoading) {
                      if (!isLoading) return const SizedBox.shrink();

                      return Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppCustomColor.brandPrimary,
                          ),
                        ),
                      );
                    },
                  ),

                  // Bottom padding
                  20.verticalSpace,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
