part of '../../../lesson.dart';

@lazySingleton
class DragAndDropCubit extends Cubit<DragAndDropState> {
  DragAndDropCubit() : super(DragAndDropState.initial());

  /// Load question and initialize available words
  void setQuestion(QuestionEntity question) {
    // Extract available words from options
    final List<String> words = question.options.map((option) => option.text).toList();

    emit(
      state.copyWith(
        question: question,
        availableWords: words,
        placedWords: {},
        hasChecked: false,
        isCorrect: false,
        showExplanation: false,
      ),
    );
  }

  /// Place a word in a drop zone
  void placeWord(int index, String word, int? fromIndex) {
    final newPlacedWords = Map<int, String>.from(state.placedWords);
    final newAvailableWords = List<String>.from(state.availableWords);

    // If word is from another drop zone, remove it from there
    if (fromIndex != null) {
      newPlacedWords.remove(fromIndex);
    } else {
      // If word is from available words, remove it
      newAvailableWords.remove(word);
    }

    // Place the word in the target drop zone
    newPlacedWords[index] = word;

    emit(
      state.copyWith(
        placedWords: newPlacedWords,
        availableWords: newAvailableWords,
      ),
    );
  }

  /// Remove a word from drop zone back to available words
  void removeWord(int index) {
    final newPlacedWords = Map<int, String>.from(state.placedWords);
    final newAvailableWords = List<String>.from(state.availableWords);

    final word = newPlacedWords[index];
    if (word != null && word.isNotEmpty) {
      newPlacedWords.remove(index);
      if (!newAvailableWords.contains(word)) {
        newAvailableWords.add(word);
      }
    }

    emit(
      state.copyWith(
        placedWords: newPlacedWords,
        availableWords: newAvailableWords,
      ),
    );
  }

  /// Check if the answer is correct
  void checkAnswer() {
    bool allCorrect = true;

    // Check if all positions match the correct answers
    for (int i = 0; i < state.question.answer.length; i++) {
      final correctAnswer = state.question.answer[i].correctAnswer;
      final placedAnswer = state.placedWords[i];

      if (placedAnswer == null || placedAnswer != correctAnswer) {
        allCorrect = false;
        break;
      }
    }

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: allCorrect,
      ),
    );

    if (!allCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  int pointCalculation() {
    /// Đúng 1 vị trí = ( Max điểm / số vị trí( câu đúng) )
    /// Sai ko bị trừ điểm
    final placedWords = state.placedWords;
    final correctAnswers = state.question.answer;

    if (placedWords.isEmpty) return 0;

    final totalPositions = correctAnswers.length;
    if (totalPositions == 0) return 0;

    final pointPerPosition = 100.0 / totalPositions;
    int correctCount = 0;

    for (int i = 0; i < totalPositions; i++) {
      final placedWord = placedWords[i];
      final correctWord = correctAnswers[i].correctAnswer;
      if (placedWord == correctWord) {
        correctCount++;
      }
    }

    final score = correctCount * pointPerPosition;

    return score.clamp(0, 100).toInt();
  }

  /// Toggle explanation visibility
  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  /// Reset the question state (for retry)
  void reset() {
    setQuestion(state.question);
  }
}
