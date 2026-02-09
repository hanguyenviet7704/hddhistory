part of '../../../lesson.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void reset() => emit(ChoiceState.initial());

  void setQuestion(QuestionEntity question) => emit(state.copyWith(question: question));

  void selectAnswer(int index) {
    if (state.hasChecked) return;

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
        if (state.isMultipleChoiceQuestion) {
          AppService.instance.appTrackingService.trackKeypointExerciseMultiClick(trackingData);
        } else {
          AppService.instance.appTrackingService.trackKeypointExerciseClick(trackingData);
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

    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType == LearningItemType.roleplay) {
      final trackingData = _roleplayTrackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayQuizCheck(trackingData);
      }
    } else {
      final trackingData = _trackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointExerciseCheckClick(trackingData);
      }
    }

    bool isCorrect = false;

    if (state.isMultipleChoiceQuestion) {
      // Check multiple choice answer
      if (state.selectedAnswersIndices.isNotEmpty) {
        Set<int> correctIndexes = state.correctOptionsIndices;
        Set<int> selectedIndexes = state.selectedAnswersIndices;
        // User is correct if they've selected all correct options
        isCorrect = correctIndexes.every((index) => selectedIndexes.contains(index));
      }
    } else if (state.isNoCorrectSingleChoiceQuestion) {
      // No-correct-answer single choice is complete once user selects any option.
      isCorrect = state.selectedAnswerIndex >= 0;
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

    final QuestionType progressType = switch (question.type) {
      QuestionTypeEnum.singleChoice => QuestionType.singleChoice,
      QuestionTypeEnum.multipleChoice => QuestionType.multipleChoice,
      _ => QuestionType.singleChoice,
    };

    final data = UpdateUserProgressExerciseData(
      exerciseId: question.exerciseId,
      type: progressType,
      passed: result.passed,
      score: score,
      multipleAnswer: state.isMultipleChoiceQuestion ? _progressOptionList(result.multipleAnswer) : null,
      singleAnswer: state.isMultipleChoiceQuestion ? null : _progressSingleOption(result.singleAnswer),
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
    if (state.isMultipleChoiceQuestion) {
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

    if (state.isNoCorrectSingleChoiceQuestion) {
      return state.selectedAnswerIndex >= 0 ? state.question.maxScore : 0;
    }

    if (state.correctOptionsIndices.isEmpty) return 0;
    final correctIndex = state.correctOptionsIndices.first;
    final selectedIndex = state.selectedAnswerIndex;
    final score = (selectedIndex == correctIndex ? state.question.maxScore : 0);
    return score;
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
    final isCorrect = state.isNoCorrectSingleChoiceQuestion ? selectedIndex >= 0 : _isSingleCorrect(question, selectedIndex);

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
  final options = question.legacyOptionsFromPayload;
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

bool _isMultipleCorrect(QuestionEntity question, Set<int> selectedIndices) {
  if (selectedIndices.isEmpty) return false;

  final options = question.legacyOptionsFromPayload;
  final correctIndices = <int>{};
  for (int i = 0; i < options.length; i++) {
    if (options[i].isCorrect) correctIndices.add(i);
  }

  return correctIndices.every((index) => selectedIndices.contains(index));
}

bool _isSingleCorrect(QuestionEntity question, int selectedIndex) {
  if (selectedIndex < 0) return false;
  if (question.payloadOrLegacy is QuestionSingleChoiceNoCorrectAnswerPayloadEntity) return true;

  final correctIndex = question.legacyOptionsFromPayload.indexWhere((option) => option.isCorrect);
  if (correctIndex == -1) return false;

  return selectedIndex == correctIndex;
}
