part of '../../course.dart';

class CourseRoadmapPage extends StatelessWidget {
  const CourseRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: BlocSelector<CourseRoadmapCubit, CourseRoadmapState, bool>(
        selector: (state) => state.status == CourseRoadmapStatus.loading && state.roadmap.levels.isEmpty,
        builder: (context, isLoading) {

          if (isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppCustomColor.brandPrimary,
              ),
            );
          }
          return Column(
            children: [
              TopProgressBar(),
              CourseRoadmapContent(),
            ],
          );
        },
      ),
    );
  }
}
