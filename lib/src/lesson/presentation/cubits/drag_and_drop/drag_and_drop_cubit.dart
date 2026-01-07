part of '../../../lesson.dart';

@lazySingleton
class DragAndDropCubit extends Cubit<DragAndDropState> {
  DragAndDropCubit() : super(DragAndDropState.initial());

  /// Load question and initialize available words
  void setQuestion(QuestionEntity question) {
    // Extract available words from options
    final List<String> words = question.options.map((option) => option.text.text).toList();

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

      if (placedAnswer == null || placedAnswer != correctAnswer.text) {
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

    _updateUserProgressExercise();

    if (!allCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise() {
    // TODO: Update user progress exercise
  }

  int pointCalculation() {
    /// Đúng 1 vị trí = ( Max điểm / số vị trí( câu đúng) )
    /// Sai ko bị trừ điểm
    final placedWords = state.placedWords;
    final correctAnswers = state.question.answer;

    if (placedWords.isEmpty) return 0;

    final totalPositions = correctAnswers.length;
    if (totalPositions == 0) return 0;

    final pointPerPosition = state.question.maxScore / totalPositions;
    int correctCount = 0;

    for (int i = 0; i < totalPositions; i++) {
      final placedWord = placedWords[i];
      final correctWord = correctAnswers[i].correctAnswer;
      if (placedWord == correctWord.text) {
        correctCount++;
      }
    }

    final score = correctCount * pointPerPosition;

    return score.clamp(0, state.question.maxScore).toInt();
  }

  /// Toggle explanation visibility
  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  /// Reset the question state (for retry)
  void reset() {
    setQuestion(state.question);
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    int totalSlots = question.answer.length;
    if (totalSlots == 0 && state.placedWords.isNotEmpty) {
      totalSlots = state.placedWords.keys.reduce(math.max) + 1;
    }

    final usedIndices = <int>{};
    final dragDropAnswer = <OptionEntity>[];

    for (int i = 0; i < totalSlots; i++) {
      final placedWord = state.placedWords[i];
      if (placedWord == null || placedWord.isEmpty) {
        dragDropAnswer.add(const OptionEntity());
        continue;
      }

      final optionIndex = _dragDropFindOptionIndex(question.options, placedWord, usedIndices);
      final sourceOption = optionIndex >= 0 ? question.options[optionIndex] : null;
      if (optionIndex >= 0) usedIndices.add(optionIndex);

      dragDropAnswer.add(_dragDropBuildOption(placedWord, sourceOption));
    }

    return ExerciseResultEntity(
      exerciseId: question.id.toString(),
      type: question.type,
      form: question.form,
      passed: state.isCorrect,
      dragDropAnswer: dragDropAnswer,
    );
  }

  void applyExerciseResult(ExerciseResultEntity result) {
    final question = state.question;
    if (question.id == 0) return;

    final placedWords = <int, String>{};
    final availableWords = question.options.map((option) => option.labelText).where((text) => text.isNotEmpty).toList();

    for (int i = 0; i < result.dragDropAnswer.length; i++) {
      final answer = result.dragDropAnswer[i];
      final label = answer.labelText;
      if (label.isEmpty) continue;

      placedWords[i] = label;
      final removeIndex = availableWords.indexOf(label);
      if (removeIndex != -1) {
        availableWords.removeAt(removeIndex);
      }
    }

    final isCorrect = _dragDropIsCorrect(question, placedWords);

    emit(
      state.copyWith(
        placedWords: placedWords,
        availableWords: availableWords,
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );
  }
}

int _dragDropFindOptionIndex(List<OptionEntity> options, String word, Set<int> usedIndices) {
  for (int i = 0; i < options.length; i++) {
    if (usedIndices.contains(i)) continue;
    final optionText = options[i].labelText;
    if (optionText == word) return i;
  }
  return -1;
}

OptionEntity _dragDropBuildOption(String word, OptionEntity? sourceOption) {
  final fallbackOption = sourceOption ?? const OptionEntity();
  return fallbackOption.withFallbackLabel(word);
}

bool _dragDropIsCorrect(QuestionEntity question, Map<int, String> placedWords) {
  bool allCorrect = true;
  for (int i = 0; i < question.answer.length; i++) {
    final correctAnswer = question.answer[i].correctAnswer.text;
    final placedAnswer = placedWords[i];
    if (placedAnswer == null || placedAnswer != correctAnswer) {
      allCorrect = false;
      break;
    }
  }
  return allCorrect;
}
