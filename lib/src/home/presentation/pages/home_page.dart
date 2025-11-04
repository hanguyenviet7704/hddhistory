part of '../../home.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeCubit>().initializeData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const HomeHeaderWidget(),

                    // Courses section
                    if (state.coursesPageData.items.isNotEmpty) ...[
                      4.verticalSpace,
                      // Continue learning
                      AppText(
                        'Continue learning',
                        style: AppStyle.textBold20.copyWith(
                          color: AppCustomColor.black36,
                        ),
                      ),
                      12.verticalSpace,
                      // Course cards horizontal scroll
                      SizedBox(
                        height: 102.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 20.w),
                          itemCount: state.coursesPageData.items.length,
                          separatorBuilder: (_, _) => 16.horizontalSpace,
                          itemBuilder: (context, index) {
                            final courseProgress = state.coursesPageData.items[index];
                            return CourseCardWidget(
                              courseProgress: courseProgress,
                              onTap: () {
                                // Navigate to course details
                                // TODO: Implement navigation
                              },
                            );
                          },
                        ),
                      ),
                      20.verticalSpace,
                    ],

                    // Skillsets section
                    const SectionHeaderWidget(
                      title: 'Recommended for you',
                      actionText: 'All courses',
                    ),
                    16.verticalSpace,

                    // Skillsets grid
                    GridView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.w,
                        mainAxisSpacing: 12.h,
                        childAspectRatio: 161.w / 234.h,
                      ),
                      itemCount: state.pageData.items.length,
                      itemBuilder: (context, index) {
                        final skillset = state.pageData.items[index];
                        return SkillsetCardWidget(
                          skillset: skillset,
                          onTap: () {
                            // Navigate to skillset details
                            // TODO: Implement navigation
                          },
                        );
                      },
                    ),

                    // Loading indicator for skillsets
                    if (state.isLoadingSkillsets)
                      Padding(
                        padding: EdgeInsets.all(20.w),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppCustomColor.blue2F,
                          ),
                        ),
                      ),

                    // Bottom padding
                    20.verticalSpace,
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
