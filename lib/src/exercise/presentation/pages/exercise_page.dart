part of '../../exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the first multiple choice question from mock data
    final question = mockChoiceQuestions.firstWhere(
      (q) => q.isMultiChoice,
      orElse: () => mockChoiceQuestions.first,
    );

    return ExerciseLayout(
      type: ExerciseLayoutType.practice,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: MultipleChoiceLessonBody(
          question: question,
          onAnswerChecked: (isCorrect) {
            // Handle answer checked event
            debugPrint('Answer is correct: $isCorrect');
          },
        ),
      ),
    );
  }
}
