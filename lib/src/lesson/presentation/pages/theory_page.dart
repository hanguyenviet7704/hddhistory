part of '../../lesson.dart';

class TheoryPage extends StatelessWidget {
  const TheoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theoryBody = TheoryLessonBody(onAnswerChecked: (isCorrect) {});
    return ExerciseLayout(
      type: LearningItemType.theory,
      body: theoryBody,
      bottom: theoryBody.buildBottomButton(context),
    );
  }
}
