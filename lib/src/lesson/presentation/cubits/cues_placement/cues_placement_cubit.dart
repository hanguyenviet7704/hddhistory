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

    _updateUserProgressExercise();

    if (!isCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise() {
    final question = state.question;
    if (question.exerciseId.isEmpty) return;
    final result = toExerciseResult();
    final double score = pointCalculation().toDouble();

    final data = UpdateUserProgressExerciseData(
      exerciseId: question.exerciseId.isNotEmpty ? question.exerciseId : question.id.toString(),
      type: QuestionType.dragAndDrop,
      form: question.form,
      passed: result.passed,
      score: score,
      dragDropAnswer: _progressDragDropList(result.dragDropAnswer),
    );

    final exerciseCubit = AppDI.injector.get<ExerciseCubit>();
    final isRoleplay = exerciseCubit.state.currentLearningItem.type == LearningItemType.roleplay;
    final LessonEntity lesson = isRoleplay ? AppDI.injector.get<RoleplayCubit>().state.currentLesson : AppDI.injector.get<CourseLessonCubit>().state.selectedLesson;
    final String courseId = lesson.courseId.isNotEmpty ? lesson.courseId : AppDI.injector.get<HomeCubit>().state.currentCourse.id;

    final params = UpdateUserProgressExerciseParams(
      userId: AppDI.injector.get<UserCubit>().state.user.id,
      courseId: courseId,
      lessonId: lesson.id,
      keypointId: question.keypoint.id,
      exercises: [data],
    );

    AppDI.injector.get<ProgressCubit>().updateUserProgressExercise(params);
  }
  int pointCalculation() {
    /// Đúng 1 vị trí = ( Max điểm / số vị trí( câu đúng) )
    /// Sai ko bị trừ điểm
    final placedPositions = state.placedMarks.keys.toSet();
    final correctPositions = state.correctPositions;

    if (placedPositions.isEmpty) return 0;

    final totalCorrectPositions = correctPositions.length;
    if (totalCorrectPositions == 0) return 0;

    final pointPerPosition = state.question.maxScore / totalCorrectPositions;
    final correctPlacements = placedPositions.where((pos) => correctPositions.contains(pos)).length;

    final score = correctPlacements * pointPerPosition;

    return score.clamp(0, state.question.maxScore).toInt();
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  void reset() {
    emit(CuesPlacementState.initial());
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final entries = state.placedMarks.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

    final dragDropAnswer = entries
        .map(
          (entry) => OptionEntity(
            id: entry.value,
            text: BaseMultiLanguage(en: entry.key.toString(), vi: entry.key.toString(), zh: entry.key.toString()),
            value: BaseMultiLanguage(en: entry.key.toString(), vi: entry.key.toString(), zh: entry.key.toString()),
          ),
        )
        .toList();

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

    final placedMarks = <int, int>{};
    for (final answer in result.dragDropAnswer) {
      final indexText = answer.labelText;
      final wordIndex = int.tryParse(indexText);
      if (wordIndex == null || wordIndex < 0) continue;
      placedMarks[wordIndex] = answer.id;
    }

    final isCorrect = _cuesPlacementIsCorrect(question, placedMarks);

    emit(
      state.copyWith(
        placedMarks: placedMarks,
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );
  }
}

bool _cuesPlacementIsCorrect(QuestionEntity question, Map<int, int> placedMarks) {
  final placedPositions = placedMarks.keys.toSet();
  final correctPositions = question.answer.map((answer) => int.tryParse(answer.correctAnswer.text) ?? 0).where((index) => index > 0).map((index) => index - 1).toSet();

  return placedPositions.length == correctPositions.length && placedPositions.every((pos) => correctPositions.contains(pos));
}
