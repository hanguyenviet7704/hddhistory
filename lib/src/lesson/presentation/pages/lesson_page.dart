part of '../../lesson.dart';

class LessonPage extends StatelessWidget {
  const LessonPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<LessonCubit, LessonState, LearningItemType>(
      selector: (state) => state.currentLearningItem.type,
      builder: (context, learningType) {
        Widget lessonBody = const SizedBox.shrink();
        Widget bottomButton = const SizedBox.shrink();

        switch (learningType) {
          case LearningItemType.exercise:
            final QuestionEntity question = context.select((ExerciseCubit bloc) => bloc.state.currentQuestion);
            lessonBody = _buildExerciseLessonBody(question.type);
            bottomButton = _buildBottomButton(context, lessonBody);
            break;
          case LearningItemType.theory:
            lessonBody = TheoryLessonBody(onAnswerChecked: _handleAnswerChecked);
            bottomButton = _buildBottomButton(context, lessonBody);
            break;
          case LearningItemType.roleplay:
            // lessonBody = RoleplayLessonBody();
            bottomButton = _buildBottomButton(context, lessonBody);
            break;
        }
        
        return LessonLayout(
          body: lessonBody,
          bottom: bottomButton,
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
