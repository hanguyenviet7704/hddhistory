part of '../../../course.dart';

class MyCourseTab extends StatelessWidget {
  const MyCourseTab({super.key});

  void _onTapCourse(BuildContext context, CourseEntity course, int index) {
    final homeState = context.read<HomeCubit>().state;
    final skillset = homeState.skillsets.resolveSkillsetByCourseId(
      course.id,
      fallback: homeState.currentSkillset,
    );
    AppService.instance.appTrackingService.trackCourseSelectCourseClick(
      skillset,
      course,
      source: 'my_course',
    );

    bool isFirstTimeUserChooseCourse = context.read<UserCubit>().state.isFirstTimeUserChooseCourse;
    if (isFirstTimeUserChooseCourse) {
      CourseIntroPopup.show(
        context,
        course: course,
        onClose: () => _handleCourseTap(context, course, index),
      );
      return;
    }

    _handleCourseTap(context, course, index);
  }

  void _handleCourseTap(BuildContext context, CourseEntity course, int index) {
    context.read<CourseRoadmapCubit>().setRoadmapSource('nav_course');
    context.read<HomeCubit>().selectCourseFromCourseId(course.id);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProgressCubit, ProgressState>(
      builder: (context, progressState) {
        final myCourses = progressState.myCourses;

        if (myCourses.isEmpty) {
          return const CourseEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProgressCubit>().loadUserProgressMyCourses(isInit: true);
          },
          child: ListView.separated(
            padding: EdgeInsets.all(20.w),
            itemCount: myCourses.length,
            separatorBuilder: (context, index) => 12.verticalSpace,
            itemBuilder: (context, index) {
              final course = myCourses[index];

              // Get progress information for "My course"
              int? completedLessons;
              int? totalLessons;
              bool showProgress = false;

              final userProgress = progressState.userProgresses.firstWhereOrNull(
                (progress) => progress.courseId == course.id,
              );

              if (userProgress != null && userProgress.lessonsResult.isNotEmpty) {
                completedLessons = userProgress.lessonsResult.where((result) => result.passed).length;
                totalLessons = course.numberOfLesson;
                showProgress = completedLessons > 0;
              }

              return CourseCard(
                course: course,
                showProgress: showProgress,
                completedLessons: completedLessons,
                totalLessons: totalLessons,
                isSelected: false,
                onTap: () => _onTapCourse(context, course, index),
              );
            },
          ),
        );
      },
    );
  }
}
