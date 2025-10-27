part of '../../../exercise.dart';

@lazySingleton
class DragAndDropCubit extends Cubit<DragAndDropState> {
  DragAndDropCubit() : super(DragAndDropState.initial());

  /// Load question and initialize available words
  void loadQuestion(QuestionEntity question) {
    // Extract available words from options
    final List<String> words = question.options.map((option) => option.text).toList();

    emit(state.copyWith(
      question: question,
      availableWords: words,
      placedWords: {},
      hasChecked: false,
      isCorrect: false,
      showExplanation: false,
    ));
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

    emit(state.copyWith(
      placedWords: newPlacedWords,
      availableWords: newAvailableWords,
    ));
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

    emit(state.copyWith(
      placedWords: newPlacedWords,
      availableWords: newAvailableWords,
    ));
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

    emit(state.copyWith(
      hasChecked: true,
      isCorrect: allCorrect,
    ));
  }

  /// Toggle explanation visibility
  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  /// Reset the question state (for retry)
  void reset() {
    loadQuestion(state.question);
  }
}
