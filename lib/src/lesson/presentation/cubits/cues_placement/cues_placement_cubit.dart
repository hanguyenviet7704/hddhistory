part of '../../../lesson.dart';

@lazySingleton
class CuesPlacementCubit extends Cubit<CuesPlacementState> {
  CuesPlacementCubit() : super(CuesPlacementState.initial());

  void setQuestion(QuestionEntity question) {
    emit(
      state.copyWith(
        question: question,
        placedMarks: {},
        hasChecked: false,
        isCorrect: false,
        showExplanation: false,
      ),
    );
  }

  /// Place a pause mark after a word at the given index
  void placePauseMark(int afterWordIndex, int markOptionId) {
    if (state.hasChecked) return;
    if (state.availableMarksCount <= 0 && !state.placedMarks.containsKey(afterWordIndex)) return;

    final updatedMarks = Map<int, int>.from(state.placedMarks);
    updatedMarks[afterWordIndex] = markOptionId;

    emit(state.copyWith(placedMarks: updatedMarks));
  }

  /// Remove a pause mark from after a word at the given index
  void removePauseMark(int afterWordIndex) {
    if (state.hasChecked) return;
    if (!state.placedMarks.containsKey(afterWordIndex)) return;

    final updatedMarks = Map<int, int>.from(state.placedMarks);
    updatedMarks.remove(afterWordIndex);

    emit(state.copyWith(placedMarks: updatedMarks));
  }

  /// Move a pause mark from one position to another
  void movePauseMark(int fromWordIndex, int toWordIndex) {
    if (state.hasChecked) return;
    if (!state.placedMarks.containsKey(fromWordIndex)) return;
    if (fromWordIndex == toWordIndex) return;

    final markId = state.placedMarks[fromWordIndex]!;
    final updatedMarks = Map<int, int>.from(state.placedMarks);
    updatedMarks.remove(fromWordIndex);
    updatedMarks[toWordIndex] = markId;

    emit(state.copyWith(placedMarks: updatedMarks));
  }

  /// Check if the placed pause marks match the correct answer
  void checkAnswer() {
    if (state.placedMarks.isEmpty || state.hasChecked) return;

    // Get the positions where marks were placed
    final placedPositions = state.placedMarks.keys.toSet();
    final correctPositions = state.correctPositions;

    // Check if placed positions exactly match correct positions
    final isCorrect = placedPositions.length == correctPositions.length && placedPositions.every((pos) => correctPositions.contains(pos));

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
    final placedPositions = state.placedMarks.keys.toSet();
    final correctPositions = state.correctPositions;
    final isCorrect = placedPositions.length == correctPositions.length && placedPositions.every((pos) => correctPositions.contains(pos));
    return isCorrect ? 100 : 0;
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  void reset() {
    emit(CuesPlacementState.initial());
  }
}
