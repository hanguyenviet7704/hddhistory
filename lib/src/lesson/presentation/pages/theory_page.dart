part of '../../lesson.dart';

class TheoryPage extends StatelessWidget {
  const TheoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theoryBody = TheoryLessonBody(onAnswerChecked: (isCorrect) {});
    return LessonLayout(
      body: theoryBody,
      bottom: theoryBody.buildBottomButton(context),
    );
  }
}
