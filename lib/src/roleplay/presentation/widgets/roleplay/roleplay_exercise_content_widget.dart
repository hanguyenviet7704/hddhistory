part of '../../../roleplay.dart';

class RoleplayExerciseContentWidget extends StatelessWidget {
  final QuestionEntity exercise;

  const RoleplayExerciseContentWidget({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    if (exercise.isCompleted) return const SizedBox.shrink();

    return Container();
  }
}
