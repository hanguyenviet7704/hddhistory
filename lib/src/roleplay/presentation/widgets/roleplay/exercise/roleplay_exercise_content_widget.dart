part of '../../../../roleplay.dart';

class RoleplayExerciseContentWidget extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isCompleted;
  final VoidCallback? onTapResult;

  const RoleplayExerciseContentWidget({
    super.key,
    required this.exercise,
    this.isCompleted = false,
    this.onTapResult,
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
          ? GestureDetector(
              onTap: () {
                final trackingData = RoleplayTrackingData.fromContext();
                if (trackingData != null) {
                  AppService.instance.appTrackingService.trackRoleplayQuizCollapsedClick(trackingData);
                }
                onTapResult?.call();
              },
              child: RoleplayExerciseAnswerCard(
                key: const ValueKey('completed'),
                exercise: exercise,
              ),
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}
