part of '../../lesson.dart';

class LessonPage extends StatelessWidget {
  const LessonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LessonCubit, LessonState, LearningItemType>(
      selector: (state) => state.currentLearningItem.type,
      builder: (context, learningType) {
        if (learningType == LearningItemType.exercise) {
          return BlocSelector<ExerciseCubit, ExerciseState, QuestionEntity>(
            selector: (state) => state.currentQuestion,
            builder: (context, question) {
              final lessonBody = _buildExerciseLessonBody(question.type);
              return LessonLayout(
                body: lessonBody,
                bottom: _buildBottomButton(context, lessonBody),
              );
            },
          );
        }

        final lessonBody = TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
        return LessonLayout(
          body: lessonBody,
          bottom: _buildBottomButton(context, lessonBody),
        );
      },
    );
  }

  void _handleAnswerChecked(bool isCorrect) {
    debugPrint('Answer is correct: $isCorrect');
  }

  Widget _buildExerciseLessonBody(QuestionTypeEnum questionType) {
    return switch (questionType) {
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
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }
}
