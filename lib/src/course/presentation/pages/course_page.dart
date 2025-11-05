part of '../../course.dart';

class CoursePage extends StatelessWidget {
  const CoursePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            const CourseHeader(),
            // Tab bar
            _buildTabBar(context),
            // Course list
            Expanded(
              child: _buildCourseList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        return BlocBuilder<CourseCubit, CourseState>(
          builder: (context, courseState) {
            final skillsets = homeState.skillsets;
            final selectedIndex = courseState.selectedTabIndex;

            // Build tab list: "My course" + skillset names
            final tabs = <({String label, int index})>[
              (label: 'My course', index: 0),
              ...skillsets.asMap().entries.map(
                    (entry) => (
                      label: entry.value.title.text.isNotEmpty
                        ? entry.value.title.text
                        : 'Skillset ${entry.key + 1}',
                      index: entry.key + 1,
                    ),
                  ),
            ];

            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              height: 48.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tabs.length,
                separatorBuilder: (context, index) => 8.horizontalSpace,
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return CourseTabChip(
                    label: tab.label,
                    isSelected: selectedIndex == tab.index,
                    onTap: () => context.read<CourseCubit>().selectTab(tab.index),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCourseList(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        return BlocBuilder<ProgressCubit, ProgressState>(
          builder: (context, progressState) {
            return BlocBuilder<CourseCubit, CourseState>(
              builder: (context, courseState) {
                final selectedIndex = courseState.selectedTabIndex;
                final skillsets = homeState.skillsets;
                final myCourses = progressState.myCourses;

                List<CourseEntity> coursesToShow;
                bool isMyCoursesTab = false;

                // Determine which courses to show
                if (selectedIndex == 0) {
                  // "My course" tab
                  coursesToShow = myCourses;
                  isMyCoursesTab = true;
                } else if (selectedIndex - 1 < skillsets.length) {
                  // Skillset tab
                  final skillsetIndex = selectedIndex - 1;
                  coursesToShow = skillsets[skillsetIndex].courses;
                } else {
                  coursesToShow = [];
                }

                if (coursesToShow.isEmpty) {
                  return Center(
                    child: AppText(
                      'No courses available',
                      style: AppStyle.text14.copyWith(
                        color: AppCustomColor.textTertiary,
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    if (isMyCoursesTab) {
                      context.read<ProgressCubit>().loadUserProgressMyCourses(isInit: true);
                    }
                  },
                  child: ListView.separated(
                    padding: EdgeInsets.all(20.w),
                    itemCount: coursesToShow.length,
                    separatorBuilder: (context, index) => 12.verticalSpace,
                    itemBuilder: (context, index) {
                      final course = coursesToShow[index];

                      // For "My course" tab, try to get progress information
                      int? completedLessons;
                      int? totalLessons;
                      bool showProgress = false;

                      if (isMyCoursesTab) {
                        // Find user progress for this course
                        final userProgress = progressState.userProgresses.firstWhereOrNull(
                          (progress) => progress.courseId == course.id,
                        );

                        if (userProgress != null && userProgress.lessonsResult.isNotEmpty) {
                          completedLessons = userProgress.lessonsResult
                              .where((result) => result.passed)
                              .length;
                          totalLessons = course.numberOfLesson;
                          showProgress = completedLessons > 0;
                        }
                      }

                      return CourseCard(
                        course: course,
                        showProgress: showProgress,
                        completedLessons: completedLessons,
                        totalLessons: totalLessons,
                        isSelected: false, // You can add selection logic if needed
                        onTap: () {
                          // Navigate to course roadmap
                          context.read<CourseRoadmapCubit>().loadRoadmap(course.id);
                          CourseRoadmapRoute().go(context);
                        },
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}