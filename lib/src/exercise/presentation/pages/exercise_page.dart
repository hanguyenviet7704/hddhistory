part of '../../exercise.dart';

class ExercisePage extends StatelessWidget {
  const ExercisePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Test data for speaking exercise
    const sentence = "The cat drinks milk";
    const audioPath = ""; // Empty for now, would be actual audio path in real implementation

    // Commented out old cues placement implementation for reuse later
    /*
    // Test data for cues placement exercise
    const sentence = "I'm really anxious about the job interview tomorrow because it feels like such an important opportunity.";
    const words = [
      "I'm",
      "really",
      "anxious",
      "about",
      "the",
      "job",
      "interview",
      "tomorrow",
      "because",
      "it",
      "feels",
      "like",
      "such",
      "an",
      "important",
      "opportunity.",
    ];
    const totalPauseMarks = 3;

    return ExerciseLayout(
      type: ExerciseLayoutType.practice,
      body: CuesPlacementLessonBody(
        sentence: sentence,
        words: words,
        totalPauseMarks: totalPauseMarks,
        onAnswerChecked: (placedMarks) {
          // Handle answer checked event
          debugPrint('Placed marks: $placedMarks');
        },
      ),
    );
    */

    // Commented out old drag and drop implementation for reuse later
    /*
    // Test data for drag and drop exercise
    const question = 'What is pause?';
    const availableWords = ['short moment', 'silence', 'speaking'];
    const correctAnswers = ['short moment', 'silence', 'speaking'];

    return ExerciseLayout(
      type: ExerciseLayoutType.practice,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: DragAndDropLessonBody(
          question: question,
          availableWords: availableWords,
          correctAnswers: correctAnswers,
          onAnswerChecked: (isCorrect) {
            // Handle answer checked event
            debugPrint('Answer is correct: $isCorrect');
          },
        ),
      ),
    );
    */

    // return ExerciseLayout(
    //   type: ExerciseLayoutType.practice,
    //   body: SpeakingLessonBody(
    //     sentence: sentence,
    //     audioPath: audioPath,
    //     onAnswerChecked: (isCompleted) {
    //       // Handle answer checked event
    //       debugPrint('Speaking exercise completed: $isCompleted');
    //     },
    //   ),
    // );

    return ExerciseLayout(
      type: ExerciseLayoutType.practice,
      body: SingleChoiceLessonBody(
        onAnswerChecked: (isCorrect) {
          // Handle answer checked event
          debugPrint('Answer is correct: $isCorrect');
        },
      ),
    );  
  }
}
