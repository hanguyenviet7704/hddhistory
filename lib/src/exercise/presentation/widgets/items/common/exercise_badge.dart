part of '../../../../exercise.dart';

class ExerciseBadge extends StatelessWidget {
  final ExerciseLayoutType type;
  const ExerciseBadge({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        spacing: 6.w,
        children: [
          SvgPicture.asset(type.icon),
          AppText(type.title),
        ],
      ),
    );
  }
}
