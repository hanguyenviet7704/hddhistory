part of '../../../lesson.dart';

@lazySingleton
class ArrangeTheSequenceCubit extends Cubit<ArrangeTheSequenceState> {
  ArrangeTheSequenceCubit() : super(ArrangeTheSequenceState.initial());

  void reset() => emit(ArrangeTheSequenceState.initial());

  /// Initialize the question and set up the items to be reordered
  void setQuestion(QuestionEntity question) {
    emit(
      state.copyWith(
        question: question,
        currentItems: List<OptionEntity>.from(question.options),
        hasChecked: false,
        isCorrect: false,
        showExplanation: false,
      ),
    );
  }

  /// Handle reordering of items
  void reorderItems(int oldIndex, int newIndex) {
    final items = List<OptionEntity>.from(state.currentItems);

    // Adjust newIndex if item is moved down the list
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Perform the reorder
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    emit(state.copyWith(currentItems: items));
  }

  /// Check if the current order matches the correct answer
  void checkAnswer() {
    final List<String> currentOrder = state.currentOrderLabels;
    final List<String> correctOrder = state.correctOrderLabels;

    // Compare the two lists
    final isCorrect = _listsEqual(currentOrder, correctOrder);

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: isCorrect,
      ),
    );

    _updateUserProgressExercise();

    if (!isCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise() {
    // TODO: Update user progress exercise
  }

  int pointCalculation() {
    /// Đúng 1 vị trí = ( Max điểm / số vị trí( câu đúng) )
    /// Sai ko bị trừ điểm
    final currentOrder = state.currentOrderLabels;
    final correctOrder = state.correctOrderLabels;

    if (currentOrder.isEmpty) return 0;

    final totalPositions = correctOrder.length;
    if (totalPositions == 0) return 0;

    final pointPerPosition = state.question.maxScore / totalPositions;
    int correctCount = 0;

    for (int i = 0; i < totalPositions; i++) {
      if (i < currentOrder.length && currentOrder[i] == correctOrder[i]) {
        correctCount++;
      }
    }

    final score = correctCount * pointPerPosition;

    return score.clamp(0, state.question.maxScore).toInt();
  }

  /// Toggle the explanation visibility
  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  /// Check if the user can submit an answer
  bool get canCheck => state.currentItems.isNotEmpty && !state.hasChecked;

  /// Helper method to compare two lists
  bool _listsEqual<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final dragDropAnswer = state.currentItems.map(_arrangeNormalizeOption).toList();

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

    List<OptionEntity> items = [];
    if (result.dragDropAnswer.isEmpty) {
      items = List<OptionEntity>.from(question.options);
    } else {
      final usedIndices = <int>{};
      for (final answer in result.dragDropAnswer) {
        final index = _arrangeFindOptionIndex(question.options, answer, usedIndices);
        if (index >= 0) {
          items.add(question.options[index]);
          usedIndices.add(index);
        } else {
          items.add(_arrangeNormalizeOption(answer));
        }
      }
    }

    final isCorrect = _arrangeIsCorrect(question, items);

    emit(
      state.copyWith(
        currentItems: items,
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );
  }
}

OptionEntity _arrangeNormalizeOption(OptionEntity option) {
  final label = option.labelText;
  return option.withFallbackLabel(label);
}

int _arrangeFindOptionIndex(List<OptionEntity> options, OptionEntity answer, Set<int> usedIndices) {
  if (answer.id != 0) {
    for (int i = 0; i < options.length; i++) {
      if (usedIndices.contains(i)) continue;
      if (options[i].id == answer.id) return i;
    }
  }

  final answerText = answer.labelText;
  if (answerText.isNotEmpty) {
    for (int i = 0; i < options.length; i++) {
      if (usedIndices.contains(i)) continue;
      if (options[i].labelText == answerText) return i;
    }
  }

  return -1;
}

String _arrangeAnswerLabel(QuestionEntity question, AnswerEntity answer) {
  if (answer.correctAnswer.text.isNotEmpty) return answer.correctAnswer.text;

  final match = question.options.firstWhere(
    (option) => option.id == answer.id,
    orElse: () => const OptionEntity(),
  );

  final matchText = match.labelText;
  return matchText;
}

bool _arrangeIsCorrect(QuestionEntity question, List<OptionEntity> currentItems) {
  final currentLabels = currentItems.map((option) => option.labelText).toList();
  final correctLabels = question.answer.map((answer) => _arrangeAnswerLabel(question, answer)).toList();

  if (currentLabels.length != correctLabels.length) return false;
  for (int i = 0; i < correctLabels.length; i++) {
    if (currentLabels[i] != correctLabels[i]) return false;
  }
  return true;
}
