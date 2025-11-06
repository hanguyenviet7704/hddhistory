part of '../../home.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
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
                BlocBuilder<ProgressCubit, ProgressState>(
                  builder: (context, state) {
                    if (state.myCourses.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        4.verticalSpace,
                        // Continue learning
                        AppText(
                          'Continue learning',
                          margin: EdgeInsets.symmetric(horizontal: 20.w),
                          style: AppStyle.textBold20.copyWith(
                            color: AppCustomColor.black36,
                          ),
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
                const SectionHeaderWidget(
                  title: 'Recommended for you',
                  actionText: 'All courses',
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
                            context.read<HomeCubit>().selectSkillsetIndex(index);
                            CourseRoute().push(context);
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
                          color: AppCustomColor.blue2F,
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
    );
  }
}
