part of '../../lesson.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentQuestion = context.select((ExerciseCubit cubit) => cubit.state.currentQuestion);
    final lessonBody = _buildLessonBody(currentQuestion);

    return ExerciseLayout(
      body: lessonBody,
      bottom: _buildBottomButton(context, lessonBody),
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
  }

  Widget _buildLessonBody(QuestionEntity question) {
    return switch (question.type) {
      QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(onAnswerChecked: _handleAnswerChecked),
      QuestionTypeEnum.speaking => SpeakingLessonBody(onAnswerChecked: _handleAnswerChecked),
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
      _ => const SizedBox.shrink(),
    };
  }
}
