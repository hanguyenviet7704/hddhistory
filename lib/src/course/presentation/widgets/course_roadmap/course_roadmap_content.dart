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
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20.h,
            children: [
              // Course header card
              CourseHeaderCard(),
              // Roadmap timeline list
              RoadmapTimelineList(),
            ],
          ),
        ),
      ),
    );
  }
}
