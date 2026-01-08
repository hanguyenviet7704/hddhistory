part of '../../../lesson.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void reset() => emit(ChoiceState.initial());

  void setQuestion(QuestionEntity question) => emit(state.copyWith(question: question));

  void selectAnswer(int index) {
    if (state.hasChecked) return;

    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      // Handle multiple choice
      final Set<int> newSelectedAnswers = Set<int>.from(state.selectedAnswersIndices);
      if (newSelectedAnswers.contains(index)) {
        newSelectedAnswers.remove(index);
      } else {
        newSelectedAnswers.add(index);
      }
      emit(state.copyWith(selectedAnswersIndices: newSelectedAnswers));
      return;
    }

    // Handle single choice
    emit(state.copyWith(selectedAnswerIndex: index));
  }

  void checkAnswer() {
    if (state.question.id == 0) return;

    bool isCorrect = false;

    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      // Check multiple choice answer
      if (state.selectedAnswersIndices.isNotEmpty) {
        Set<int> correctIndexes = state.correctOptionsIndices;
        Set<int> selectedIndexes = state.selectedAnswersIndices;
        // User is correct if they've selected all correct options
        isCorrect = correctIndexes.every((index) => selectedIndexes.contains(index));
      }
    } else {
      // Check single choice answer
      isCorrect = state.correctOptionsIndices.contains(state.selectedAnswerIndex);
    }

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
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

    final QuestionType progressType = switch (question.type) {
      QuestionTypeEnum.singleChoice => QuestionType.singleChoice,
      QuestionTypeEnum.multipleChoice => QuestionType.multipleChoice,
      _ => QuestionType.singleChoice,
    };

    final data = UpdateUserProgressExerciseData(
      exerciseId: question.id.toString(),
      type: progressType,
      passed: result.passed,
      multipleAnswer: question.type == QuestionTypeEnum.multipleChoice ? _progressOptionList(result.multipleAnswer) : null,
      singleAnswer: question.type == QuestionTypeEnum.singleChoice ? _progressSingleOption(result.singleAnswer) : null,
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
    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      /// Mỗi câu chọn đúng = Max điểm / tổng số câu đúng
      /// Mỗi câu chọn sai → sẽ bị trừ 50% số điểm của 1 câu đúng. Trừ đến khi về 0 thì thôi
      /// Không chọn→  0 điểm
      final correctIndexes = state.correctOptionsIndices;
      final selectedIndexes = state.selectedAnswersIndices;

      if (selectedIndexes.isEmpty) return 0;

      final correctCount = correctIndexes.length;
      final pointPerCorrect = state.question.maxScore / correctCount;

      final correctSelections = selectedIndexes.where((index) => correctIndexes.contains(index)).length;
      final wrongSelections = selectedIndexes.where((index) => !correctIndexes.contains(index)).length;

      final score = (correctSelections * pointPerCorrect) - (wrongSelections * pointPerCorrect * 0.5);

      return score.clamp(0, state.question.maxScore).toInt();
    }

    final correctIndex = state.correctOptionsIndices.first;
    final selectedIndex = state.selectedAnswerIndex;
    final score = (selectedIndex == correctIndex ? state.question.maxScore : 0);
    return score;
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final isMultiple = question.type == QuestionTypeEnum.multipleChoice;

    final List<OptionEntity> multipleAnswer = isMultiple
        ? (state.selectedAnswersIndices.toList()..sort()).where((index) => index >= 0 && index < question.options.length).map((index) => question.options[index]).toList()
        : const [];

    final OptionEntity singleAnswer = !isMultiple && state.selectedAnswerIndex >= 0 && state.selectedAnswerIndex < question.options.length
        ? question.options[state.selectedAnswerIndex]
        : const OptionEntity();

    return ExerciseResultEntity(
      exerciseId: question.id.toString(),
      type: question.type,
      form: question.form,
      passed: state.isCorrect,
      multipleAnswer: multipleAnswer,
      singleAnswer: singleAnswer,
    );
  }

  void applyExerciseResult(ExerciseResultEntity result) {
    final question = state.question;
    if (question.id == 0) return;

    if (question.type == QuestionTypeEnum.multipleChoice) {
      final selectedIndices = <int>{};
      final usedIndices = <int>{};

      for (final answer in result.multipleAnswer) {
        final index = _findOptionIndex(question, answer, usedIndices);
        if (index >= 0) {
          selectedIndices.add(index);
          usedIndices.add(index);
        }
      }

      final isCorrect = _isMultipleCorrect(question, selectedIndices);

      emit(
        state.copyWith(
          selectedAnswersIndices: selectedIndices,
          selectedAnswerIndex: -1,
          hasChecked: true,
          isCorrect: isCorrect,
          showExplanation: false,
        ),
      );
      return;
    }

    final selectedIndex = _findOptionIndex(question, result.singleAnswer, <int>{});
    final isCorrect = _isSingleCorrect(question, selectedIndex);

    emit(
      state.copyWith(
        selectedAnswerIndex: selectedIndex,
        selectedAnswersIndices: const <int>{},
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );
  }
}

int _findOptionIndex(QuestionEntity question, OptionEntity answer, Set<int> usedIndices) {
  if (answer.id != 0) {
    for (int i = 0; i < question.options.length; i++) {
      if (usedIndices.contains(i)) continue;
      if (question.options[i].id == answer.id) return i;
    }
  }

  final answerText = answer.labelText;
  if (answerText.isNotEmpty) {
    for (int i = 0; i < question.options.length; i++) {
      if (usedIndices.contains(i)) continue;
      final option = question.options[i];
      final optionText = option.labelText;
      if (optionText == answerText) return i;
    }
  }

  return -1;
}

bool _isMultipleCorrect(QuestionEntity question, Set<int> selectedIndices) {
  if (selectedIndices.isEmpty) return false;

  final correctIndices = <int>{};
  for (int i = 0; i < question.options.length; i++) {
    if (question.options[i].isCorrect) correctIndices.add(i);
  }

  return correctIndices.every((index) => selectedIndices.contains(index));
}

bool _isSingleCorrect(QuestionEntity question, int selectedIndex) {
  if (selectedIndex < 0) return false;

  final correctIndex = question.options.indexWhere((option) => option.isCorrect);
  if (correctIndex == -1) return false;

  return selectedIndex == correctIndex;
}
