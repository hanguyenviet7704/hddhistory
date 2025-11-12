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

    if (!isCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }

    LearningItemEntity learningItem = AppDI.injector.get<LessonCubit>().state.currentLearningItem;
    if (learningItem.type == LearningItemType.roleplay) {
      KeypointEntity point = state.question.keypoint.copyWith(point: pointCalculation());
      AppDI.injector.get<RoleplayPointCubit>().setPoint(point);
    }
  }

  void setPoint() {
    KeypointEntity point = state.question.keypoint.copyWith(point: pointCalculation());
    AppDI.injector.get<RoleplayPointCubit>().setPoint(point);
  }

  int pointCalculation() {
    /// Đúng 1 vị trí = ( Max điểm / số vị trí( câu đúng) )
    /// Sai ko bị trừ điểm
    final currentOrder = state.currentItems.map((item) => item.id).toList();
    final correctOrder = state.question.answer.map((answer) => answer.id).toList();

    if (currentOrder.isEmpty) return 0;

    final totalPositions = correctOrder.length;
    if (totalPositions == 0) return 0;

    final pointPerPosition = 100.0 / totalPositions;
    int correctCount = 0;

    for (int i = 0; i < totalPositions; i++) {
      if (i < currentOrder.length && currentOrder[i] == correctOrder[i]) {
        correctCount++;
      }
    }

    final score = correctCount * pointPerPosition;

    return score.clamp(0, 100).toInt();
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
