part of '../../../course.dart';

class LessonDescription extends StatelessWidget {
  final String description;

  const LessonDescription({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return AppText(
      description,
      style: AppStyle.text14.copyWith(
        color: AppCustomColor.textSecondary,
        height: 1.75,
      ),
    );
  }
}
