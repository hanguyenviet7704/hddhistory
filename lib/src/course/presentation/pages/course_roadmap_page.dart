part of '../../course.dart';

class CourseRoadmapPage extends StatelessWidget {
  const CourseRoadmapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppCustomColor.backgroundGray,
      body: SafeArea(
        child: Column(
          children: [
            // Top progress bar
            TopProgressBar(),
            // Main content
            CourseRoadmapContent(),
          ],
        ),
      ),
    );
  }
}
