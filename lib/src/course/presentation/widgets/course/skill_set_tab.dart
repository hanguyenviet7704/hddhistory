part of '../../../course.dart';

class SkillSetTab extends StatelessWidget {
  final SkillsetEntity skillset;
  const SkillSetTab({super.key, required this.skillset});

  void _onTapCourse(BuildContext context, CourseEntity course, int index) {
    bool isFirstTimeUserChooseCourse = context.read<UserCubit>().state.isFirstTimeUserChooseCourse;
    if (isFirstTimeUserChooseCourse) {
      CourseIntroPopup.show(context);
      return;
    }

    _handleCourseTap(context, course, index);
  }

  void _handleCourseTap(BuildContext context, CourseEntity course, int index) {
    if (course.numberOfLesson == 0) {
      CourseLessonEmptyNotiPopup.show(context);
      return;
    }

    context.read<HomeCubit>()
      ..selectSkillset(skillset)
      ..selectCourseIndex(index);
    CourseRoadmapRoute().go(context);
    context.read<PageCubit>().setCurrentIndex(1);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        final courses = skillset.courses;

        if (courses.isEmpty) {
          return const CourseEmptyState();
        }

        return ListView.separated(
          padding: EdgeInsets.all(20.w),
          itemCount: courses.length,
          separatorBuilder: (context, index) => 12.verticalSpace,
          itemBuilder: (context, index) {
            final course = courses[index];

            return CourseCard(
              course: course,
              showProgress: false,
              isSelected: state.isSelectedCourse(course.id),
              onTap: () => _onTapCourse(context, course, index),
            );
          },
        );
      },
    );
  }
}
