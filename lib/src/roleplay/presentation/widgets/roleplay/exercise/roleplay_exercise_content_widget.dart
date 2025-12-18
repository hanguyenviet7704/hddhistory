part of '../../../../roleplay.dart';

class RoleplayExerciseContentWidget extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isExpanded;

  const RoleplayExerciseContentWidget({
    super.key,
    required this.exercise,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    if (exercise.isCompleted) return const SizedBox.shrink();

    return RoleplayExerciseOverlay(
      exercise: exercise,
      isExpanded: isExpanded,
    );
  }
}
