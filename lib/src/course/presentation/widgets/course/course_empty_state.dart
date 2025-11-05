part of '../../../course.dart';

class CourseEmptyState extends StatelessWidget {
  const CourseEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppText(
        'No courses available',
        style: AppStyle.text14.copyWith(
          color: AppCustomColor.textTertiary,
        ),
      ),
    );
  }
}
