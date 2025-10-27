part of '../../exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lessonBody = DragAndDropLessonBody(
      onAnswerChecked: (isCorrect) {
        // Handle answer checked event
        debugPrint('Answer is correct: $isCorrect');
      },
    );

    return ExerciseLayout(
      type: ExerciseLayoutType.practice,
      body: lessonBody,
      bottom: lessonBody.buildBottomButton(context),
    );
  }
}
