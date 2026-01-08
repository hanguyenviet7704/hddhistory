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

    _updateUserProgressExercise();

    if (!isCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise() {
    final question = state.question;
    if (question.id == 0) return;
    final result = toExerciseResult();

    final data = UpdateUserProgressExerciseData(
      exerciseId: question.id.toString(),
      type: QuestionType.dragAndDrop,
      form: question.form,
      passed: result.passed,
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
    final correctIndices = state.correctWordIndices;
    final selectedIndices = state.selectedWordIndices;

    if (selectedIndices.isEmpty) return 0;

    final totalCorrectWords = correctIndices.length;
    if (totalCorrectWords == 0) return 0;

    final pointPerWord = state.question.maxScore / totalCorrectWords;
    final correctSelections = selectedIndices.where((index) => correctIndices.contains(index)).length;

    final score = correctSelections * pointPerWord;

    return score.clamp(0, state.question.maxScore).toInt();
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  void reset() {
    emit(MarkStressWordState.initial());
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final indices = state.selectedWordIndices.toList()..sort();
    final words = state.words;

    final dragDropAnswer = indices
        .where((index) => index >= 0 && index < words.length)
        .map(
          (index) {
            final word = words[index];
            return OptionEntity(
              id: index,
              text: BaseMultiLanguage(en: word, vi: word, zh: word),
              value: BaseMultiLanguage(en: word, vi: word, zh: word),
            );
          },
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

    final words = state.words;
    final selectedIndices = <int>{};
    final usedIndices = <int>{};

    for (final answer in result.dragDropAnswer) {
      if (answer.id >= 0 && answer.id < words.length) {
        selectedIndices.add(answer.id);
        usedIndices.add(answer.id);
        continue;
      }

      final label = answer.labelText;
      if (label.isEmpty) continue;

      for (int i = 0; i < words.length; i++) {
        if (usedIndices.contains(i)) continue;
        if (words[i] == label) {
          selectedIndices.add(i);
          usedIndices.add(i);
          break;
        }
      }
    }

    final isCorrect = _stressWordIsCorrect(question, selectedIndices);

    emit(
      state.copyWith(
        selectedWordIndices: selectedIndices,
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );
  }
}

bool _stressWordIsCorrect(QuestionEntity question, Set<int> selectedIndices) {
  final correctIndices = question.answer
      .map((answer) => int.tryParse(answer.correctAnswer.text) ?? 0)
      .where((index) => index > 0)
      .map((index) => index - 1)
      .toSet();

  return selectedIndices.length == correctIndices.length && selectedIndices.every((index) => correctIndices.contains(index));
}
