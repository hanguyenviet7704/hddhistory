part of '../../../course.dart';

class CourseRoadmapContent extends StatelessWidget {
  const CourseRoadmapContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async {
          // final courseId = progress.courseId.isNotEmpty ? progress.courseId : course.id;
          // if (courseId.isNotEmpty) {
          //   context.read<CourseCubit>().loadRoadmap(courseId);
          // }
        },
        child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, RoadmapEntity>(
          selector: (state) => state.roadmap,
          builder: (context, roadmap) {
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              separatorBuilder: (context, index) => 20.verticalSpace,
              itemCount: roadmap.levels.length,
              itemBuilder: (context, index) {
                return CourseLevelContent(
                  level: roadmap.levels[index],
                  usingAppProgressLessons: roadmap.usingAppProgressLessons(index),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
