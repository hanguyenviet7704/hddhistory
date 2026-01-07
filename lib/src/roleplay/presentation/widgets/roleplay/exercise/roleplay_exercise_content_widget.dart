part of '../../../../roleplay.dart';

class RoleplayExerciseContentWidget extends StatelessWidget {
  final QuestionEntity exercise;
  final int contentIndex;
  final bool isCompleted;

  const RoleplayExerciseContentWidget({
    super.key,
    required this.exercise,
    required this.contentIndex,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldShowCompleted = isCompleted || exercise.isCompleted;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: shouldShowCompleted
          ? RoleplayExerciseAnswerCard(
              key: const ValueKey('completed'),
              exercise: exercise,
              contentIndex: contentIndex,
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
