part of '../../../../exercise.dart';

class ExerciseHeader extends StatelessWidget {
  const ExerciseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ExerciseProgressBar(),
        12.verticalSpace,
        ExerciseBadge(),
        ChatInformationWidget(),
      ],
    );
  }
}
