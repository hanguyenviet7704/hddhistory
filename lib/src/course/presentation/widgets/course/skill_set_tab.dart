part of '../../../course.dart';

class SkillSetTab extends StatelessWidget {
  final SkillsetEntity skillset;
  const SkillSetTab({super.key, required this.skillset});

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
              isSelected: false,
              onTap: () {
                context.read<CourseRoadmapCubit>().loadRoadmap(course.id);
                CourseRoadmapRoute().go(context);
              },
            );
          },
        );
      },
    );
  }
}
