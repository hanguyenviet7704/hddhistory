part of '../../../../roleplay.dart';

class _ExpandedExerciseBody extends StatelessWidget {
  final QuestionEntity exercise;
  final VoidCallback? onCheckPressed;

  const _ExpandedExerciseBody({
    required this.exercise,
    this.onCheckPressed,
  });

  void _handleAnswerChecked(BuildContext context, bool isCorrect) {
    RoleplayExerciseResultOverlayManager.show(
      context: context,
      builder: (_) => RoleplayExerciseResultBottomSheet(
        isCorrect: isCorrect,
        onContinue: () {
          RoleplayExerciseResultOverlayManager.hide();
          onCheckPressed?.call();
        },
      ),
    );
  }

  Widget _buildExerciseLessonBody(BuildContext context, QuestionTypeEnum questionType) {
    return switch (questionType) {
      QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
      QuestionTypeEnum.speaking => SpeakingLessonBody(
        onAnswerChecked: (isCorrect) => _handleAnswerChecked(context, isCorrect),
      ),
    };
  }

  Widget _buildBottomButton(BuildContext context, Widget lessonBody) {
    return switch (lessonBody) {
      SingleChoiceLessonBody body => body.buildBottomButton(context),
      MultipleChoiceLessonBody body => body.buildBottomButton(context),
      DragAndDropLessonBody body => body.buildBottomButton(context),
      ArrangeTheSequenceLessonBody body => body.buildBottomButton(context),
      CuesPlacementLessonBody body => body.buildBottomButton(context),
      MarkStressWordLessonBody body => body.buildBottomButton(context),
      SpeakingLessonBody body => body.buildBottomButton(context),
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget lessonBody = _buildExerciseLessonBody(context, exercise.type);
    Widget bottomButton = _buildBottomButton(context, lessonBody);
    return SingleChildScrollView(
      child: Column(
        children: [
          lessonBody,
          60.verticalSpace,
          bottomButton,
        ],
      ),
    );
  }
}
