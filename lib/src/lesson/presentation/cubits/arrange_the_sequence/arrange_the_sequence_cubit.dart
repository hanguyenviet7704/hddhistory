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
        currentItems: List<OptionEntity>.from(questionRuntimeOptions(question)),
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

    final exerciseType = AppDI.injector.get<ExerciseCubit>().state.currentLearningItem.type;
    if (exerciseType == LearningItemType.roleplay) {
      final trackingData = _roleplayTrackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackRoleplayQuizArrange(trackingData);
      }
    } else {
      final trackingData = _trackingData();
      if (trackingData != null) {
        AppService.instance.appTrackingService.trackKeypointExerciseArrange(trackingData);
      }
    }

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

    final result = toExerciseResult();
    _storeLessonResult(result);

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

    _updateUserProgressExercise(result);

    if (!isCorrect) {
      AppDI.injector.get<ExerciseCubit>().addSubQuestionToLessonCubit();
    }
  }

  void _updateUserProgressExercise(ExerciseResultEntity result) {
    final question = state.question;
    if (question.exerciseId.isEmpty) return;
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

    final runtimeOptions = questionRuntimeOptions(question);
    List<OptionEntity> items = [];
    if (result.dragDropAnswer.isEmpty) {
      items = List<OptionEntity>.from(runtimeOptions);
    } else {
      final usedIndices = <int>{};
      for (final answer in result.dragDropAnswer) {
        final index = _arrangeFindOptionIndex(runtimeOptions, answer, usedIndices);
        if (index >= 0) {
          items.add(runtimeOptions[index]);
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

  final match = questionRuntimeOptions(question).firstWhere(
    (option) => option.id == answer.id,
    orElse: () => const OptionEntity(),
  );

  final matchText = match.labelText;
  return matchText;
}

bool _arrangeIsCorrect(QuestionEntity question, List<OptionEntity> currentItems) {
  final currentLabels = currentItems.map((option) => option.labelText).toList();
  final correctLabels = questionRuntimeAnswers(question).map((answer) => _arrangeAnswerLabel(question, answer)).toList();

  if (currentLabels.length != correctLabels.length) return false;
  for (int i = 0; i < correctLabels.length; i++) {
    if (currentLabels[i] != correctLabels[i]) return false;
  }
  return true;
}
