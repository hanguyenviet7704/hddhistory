part of '../../lesson.dart';

class LessonPage extends StatelessWidget {
  const LessonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LessonCubit, LessonState>(
      builder: (context, state) {
        return LessonLayout(
          body: _buildLessonBody(context, state.currentLearningItem),
          bottom: _buildBottomButton(context, _buildLessonBody(context, state.currentLearningItem)),
        );
      },
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
  }

  Widget _buildLessonBody(BuildContext context, LearningItemEntity learningItem) {
    if (learningItem.type == LearningItemType.exercise) {
      return BlocSelector<ExerciseCubit, ExerciseState, QuestionEntity>(
        selector: (state) => state.currentQuestion,
        builder: (context, question) {
          return switch (question.type) {
            QuestionTypeEnum.singleChoice => SingleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.multipleChoice => MultipleChoiceLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.dragAndDrop => DragAndDropLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.arrangeTheSequence => ArrangeTheSequenceLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.cuesPlacement => CuesPlacementLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.stressPlacement => MarkStressWordLessonBody(onAnswerChecked: _handleAnswerChecked),
            QuestionTypeEnum.speaking => SpeakingLessonBody(onAnswerChecked: _handleAnswerChecked),
          };
        },
      );
    }

    return TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
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
}
