part of '../../../lesson.dart';

@lazySingleton
class ArrangeTheSequenceCubit extends Cubit<ArrangeTheSequenceState> {
  ArrangeTheSequenceCubit() : super(ArrangeTheSequenceState.initial());

  /// Initialize the question and set up the items to be reordered
  void loadQuestion(QuestionEntity question) {
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
    final currentOrder = state.currentItems.map((item) => item.id).toList();
    final correctOrder = state.question.answer.map((answer) => answer.id).toList();

    // Compare the two lists
    final isCorrect = _listsEqual(currentOrder, correctOrder);

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: isCorrect,
      ),
    );
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
}
