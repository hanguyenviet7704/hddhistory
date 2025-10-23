part of '../../../../exercise.dart';

class ExerciseHeader extends StatelessWidget {
  final ExerciseLayoutType type;
  const ExerciseHeader({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExerciseProgressBar(),
        12.verticalSpace,
        ExerciseBadge(type: type),
        ChatInformationWidget(),
      ],
    );
  }
}
