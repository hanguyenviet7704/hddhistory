part of '../../../course.dart';

class CourseRoadmapContent extends StatelessWidget {
  const CourseRoadmapContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () async => context.read<CourseRoadmapCubit>().loadRoadmap(),
        child: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, RoadmapEntity>(
          selector: (state) => state.roadmap,
          builder: (context, roadmap) {
            if (roadmap.levels.isEmpty) return const CourseEmptyState();
            return ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              separatorBuilder: (context, index) => 20.verticalSpace,
              itemCount: roadmap.levels.length,
              itemBuilder: (context, index) {
                return CourseLevelContent(
                  roadmapLevel: roadmap.levels[index],
                  usingAppProgressLessons: roadmap.usingAppProgressLessons(index),
                  roadmapLevelIndex: index,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
