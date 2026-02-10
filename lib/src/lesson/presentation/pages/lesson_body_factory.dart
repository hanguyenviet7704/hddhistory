part of '../../lesson.dart';

class LessonBodyFactory {
  LessonBodyFactory({
    required ValueChanged<bool> onAnswerChecked,
    required VoidCallback onContinueUnsupported,
    required LessonReviewBodyBuilder reviewBodyBuilder,
  }) : _onAnswerChecked = onAnswerChecked,
       _onContinueUnsupported = onContinueUnsupported,
       _reviewBodyBuilder = reviewBodyBuilder;

  final ValueChanged<bool> _onAnswerChecked;
  final VoidCallback _onContinueUnsupported;
  final LessonReviewBodyBuilder _reviewBodyBuilder;

  Widget buildExerciseBody(QuestionEntity question) {
    final payload = question.typedPayload;

    return switch (payload) {
      QuestionSingleChoicePayloadEntity() => SingleChoiceLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionSingleChoiceNoCorrectAnswerPayloadEntity() => SingleChoiceLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionMultipleChoicePayloadEntity() => MultipleChoiceLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionDragAndDropPayloadEntity() => DragAndDropLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionArrangeTheSequencePayloadEntity() => ArrangeTheSequenceLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionCuesPlacementPayloadEntity() => CuesPlacementLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionStressPlacementPayloadEntity() => MarkStressWordLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionSpeakingPayloadEntity() => SpeakingLessonBody(onAnswerChecked: _onAnswerChecked),
      QuestionUnsupportedPayloadEntity() => UnsupportedLessonBody(
        question: question,
        onContinue: _onContinueUnsupported,
      ),
      _ => UnsupportedLessonBody(
        question: question,
        onContinue: _onContinueUnsupported,
      ),
    };
  }

  Widget buildReviewBody(QuestionEntity question) {
    return _reviewBodyBuilder.buildReviewBody(question);
  }

  Widget buildBottomButton(BuildContext context, Widget lessonBody) {
    return switch (lessonBody) {
      SingleChoiceLessonBody body => body.buildBottomButton(context),
      MultipleChoiceLessonBody body => body.buildBottomButton(context),
      DragAndDropLessonBody body => body.buildBottomButton(context),
      ArrangeTheSequenceLessonBody body => body.buildBottomButton(context),
      CuesPlacementLessonBody body => body.buildBottomButton(context),
      MarkStressWordLessonBody body => body.buildBottomButton(context),
      SpeakingLessonBody body => body.buildBottomButton(context),
      UnsupportedLessonBody body => body.buildBottomButton(context),
      TheoryLessonBody body => body.buildBottomButton(context),
      _ => const SizedBox.shrink(),
    };
  }
}
