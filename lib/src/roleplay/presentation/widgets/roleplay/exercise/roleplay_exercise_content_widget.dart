part of '../../../../roleplay.dart';

class RoleplayExerciseContentWidget extends StatelessWidget {
  final QuestionEntity exercise;
  final bool isCompleted;

  const RoleplayExerciseContentWidget({
    super.key,
    required this.exercise,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool shouldShowCompleted = isCompleted || exercise.isCompleted;
    final String questionText = exercise.document.isNotEmpty ? exercise.document.first.data.content.text : '';

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
          ? _CompletedExercisePlaceholder(
              key: const ValueKey('completed'),
              questionText: questionText,
            )
          : const SizedBox.shrink(key: ValueKey('empty')),
    );
  }
}

class _CompletedExercisePlaceholder extends StatelessWidget {
  final String questionText;

  const _CompletedExercisePlaceholder({
    super.key,
    required this.questionText,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppCustomColor.backgroundWhite,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppCustomColor.borderSecondary,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              size: 20.w,
              color: AppCustomColor.brandPrimary,
            ),
            12.horizontalSpace,
            Expanded(
              child: AppText(
                questionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppStyle.text14.copyWith(
                  color: AppCustomColor.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
