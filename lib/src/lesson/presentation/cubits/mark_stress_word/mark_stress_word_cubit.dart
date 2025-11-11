part of '../../../lesson.dart';

@lazySingleton
class MarkStressWordCubit extends Cubit<MarkStressWordState> {
  MarkStressWordCubit() : super(MarkStressWordState.initial());

  void setQuestion(QuestionEntity question) {
    emit(
      state.copyWith(
        question: question,
        selectedWordIndices: {},
        hasChecked: false,
        isCorrect: false,
        showExplanation: false,
      ),
    );
  }

  /// Toggle word selection (add if not selected, remove if already selected)
  void selectWord(int index) {
    if (state.hasChecked) return;

    final updatedSelection = Set<int>.from(state.selectedWordIndices);
    if (updatedSelection.contains(index)) {
      updatedSelection.remove(index);
    } else {
      updatedSelection.add(index);
    }

    emit(state.copyWith(selectedWordIndices: updatedSelection));
  }

  /// Check if selected words match all correct answers
  void checkAnswer() {
    if (state.selectedWordIndices.isEmpty || state.hasChecked) return;

    // Get correct word indices (0-based)
    final correctIndices = state.correctWordIndices;

    // Check if selected indices exactly match correct indices
    final isCorrect = state.selectedWordIndices.length == correctIndices.length && state.selectedWordIndices.every((index) => correctIndices.contains(index));

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
      RoleplayPointEntity point = RoleplayPointEntity(keypoint: state.question.keypoint, point: pointCalculation());
      AppDI.injector.get<RoleplayPointCubit>().setPoint(point);
    }
  }

  int pointCalculation() {
    final correctIndices = state.correctWordIndices;
    final selectedIndices = state.selectedWordIndices;
    final isCorrect = selectedIndices.length == correctIndices.length && selectedIndices.every((index) => correctIndices.contains(index));
    return isCorrect ? 100 : 0;
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  void reset() {
    emit(MarkStressWordState.initial());
  }
}
