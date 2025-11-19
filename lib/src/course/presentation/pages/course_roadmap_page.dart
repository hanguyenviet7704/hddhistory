part of '../../course.dart';

class CourseRoadmapPage extends StatelessWidget {
  const CourseRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: Column(
        children: [
          TopProgressBar(),
          CourseRoadmapContent(),
        ],
      ),
    );
  }
}
