part of '../../../lesson.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void reset() => emit(ChoiceState.initial());

  void setQuestion(QuestionEntity question) => emit(state.copyWith(question: question));

  void selectAnswer(int index) {
    if (state.hasChecked) return;
    AppHaptic.select();

    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType == LearningItemType.roleplay) {
      final trackingData = _roleplayTrackingData();
      if (trackingData != null) {
        if (state.isMultipleChoiceQuestion) {
          AppService.instance.appTrackingService.trackRoleplayQuizMultiSelect(trackingData);
        } else {
          AppService.instance.appTrackingService.trackRoleplayQuizSingSelect(trackingData);
        }
      }
    } else {
      final trackingData = _trackingData();
      if (trackingData != null) {
        // keypoint_exercise_click (single-choice) tracking removed per request.
        if (state.isMultipleChoiceQuestion) {
          AppService.instance.appTrackingService.trackKeypointExerciseMultiClick(trackingData);
        }
      }
    }

    if (state.isMultipleChoiceQuestion) {
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

    // Resolve correctness FIRST so keypoint_exs_check_click can carry
    // answer_correct (learning spec).
    final isCorrect = resolveChoiceCheckResult(
      isMultipleChoice: state.isMultipleChoiceQuestion,
      isNoCorrectSingleChoice: state.isNoCorrectSingleChoiceQuestion,
      selectedAnswerIndex: state.selectedAnswerIndex,
      selectedAnswersIndices: state.selectedAnswersIndices,
      correctOptionsIndices: state.correctOptionsIndices,
    );

    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType == LearningItemType.roleplay) {
      final trackingData = _roleplayTrackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayQuizCheck(trackingData);
      }
    } else {
      final trackingData = _trackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointExerciseCheckClick(trackingData, answerCorrect: isCorrect);
      }
    }

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: isCorrect,
        showExplanation: false,
      ),
    );

    final result = toExerciseResult();
    _storeLessonResult(result);
    _updateUserProgressExercise(result);

    if (!isCorrect && !state.isNoCorrectSingleChoiceQuestion) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise(ExerciseResultEntity result) {
    final question = state.question;
    if (question.id == 0) return;
    final double score = pointCalculation().toDouble();

    final QuestionType progressType = progressQuestionTypeFromPayload(state.payload);

    final data = UpdateUserProgressExerciseData(
      exerciseId: question.exerciseId,
      type: progressType,
      passed: result.passed,
      score: score,
      multipleAnswer: state.isMultipleChoiceQuestion ? _progressOptionList(result.multipleAnswer) : null,
      singleAnswer: state.isMultipleChoiceQuestion
          ? null
          : state.isNoCorrectSingleChoiceQuestion
          ? progressSingleOptionNoCorrect(result.singleAnswer)
          : _progressSingleOption(result.singleAnswer),
    );

    final exerciseCubit = AppDI.injector.get<ExerciseCubit>();
    final isRoleplay = exerciseCubit.state.currentLearningItem.type == LearningItemType.roleplay;
    final LessonEntity lesson = isRoleplay ? AppDI.injector.get<RoleplayCubit>().state.currentLesson : AppDI.injector.get<CourseLessonCubit>().state.selectedLesson;
    final String courseId = lesson.courseId.isNotEmpty ? lesson.courseId : AppDI.injector.get<HomeCubit>().state.currentCourse.id;

    final params = UpdateUserProgressExerciseParams(
      userId: AppDI.injector.get<UserCubit>().state.user.id,
      courseId: courseId,
      lessonId: lesson.id,
      keypointId: question.keypointId,
      exercises: [data],
    );

    AppDI.injector.get<ProgressCubit>().updateUserProgressExercise(params);
  }

  void _storeLessonResult(ExerciseResultEntity result) {
    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType != LearningItemType.exercise) return;
    AppDI.injector.get<LessonCubit>().storeExerciseResult(state.question, result);
  }

  int pointCalculation() {
    return calculateChoiceScore(
      isMultipleChoice: state.isMultipleChoiceQuestion,
      isNoCorrectSingleChoice: state.isNoCorrectSingleChoiceQuestion,
      maxScore: state.question.maxScore,
      correctOptionsIndices: state.correctOptionsIndices,
      selectedAnswersIndices: state.selectedAnswersIndices,
      selectedAnswerIndex: state.selectedAnswerIndex,
    );
  }

  void toggleExplanation() {
    final shouldShow = !state.showExplanation;
    emit(state.copyWith(showExplanation: shouldShow));

    final trackingData = _trackingData();
    if (trackingData == null) return;
    if (shouldShow) {
      AppService.instance.appTrackingService.trackKeypointExerciseExplainClick(trackingData);
      AppService.instance.appTrackingService.trackKeypointExerciseExplainView(trackingData);
      return;
    }

    AppService.instance.appTrackingService.trackKeypointExerciseExplainClose(trackingData);
  }

  KeypointTrackingData? _trackingData() {
    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType != LearningItemType.exercise) return null;
    return KeypointTrackingData.fromContext();
  }

  RoleplayTrackingData? _roleplayTrackingData() {
    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType != LearningItemType.roleplay) return null;
    return RoleplayTrackingData.fromContext();
  }

  ExerciseResultEntity toExerciseResult() {
    final question = state.question;
    final isMultiple = state.isMultipleChoiceQuestion;
    final options = state.answerOptions;

    final List<OptionEntity> multipleAnswer = isMultiple
        ? (state.selectedAnswersIndices.toList()..sort()).where((index) => index >= 0 && index < options.length).map((index) => options[index]).toList()
        : const [];

    final OptionEntity singleAnswer = !isMultiple && state.selectedAnswerIndex >= 0 && state.selectedAnswerIndex < options.length
        ? options[state.selectedAnswerIndex]
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

    if (state.isMultipleChoiceQuestion) {
      final selectedIndices = <int>{};
      final usedIndices = <int>{};

      for (final answer in result.multipleAnswer) {
        final index = _findOptionIndex(question, answer, usedIndices);
        if (index >= 0) {
          selectedIndices.add(index);
          usedIndices.add(index);
        }
      }

      final isCorrect = choiceIsMultipleCorrect(question, selectedIndices);

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
    final isCorrect = state.isNoCorrectSingleChoiceQuestion ? selectedIndex >= 0 : choiceIsSingleCorrect(question, selectedIndex);

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
  final options = questionRuntimeOptions(question);
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
      final option = options[i];
      final optionText = option.labelText;
      if (optionText == answerText) return i;
    }
  }

  return -1;
}
