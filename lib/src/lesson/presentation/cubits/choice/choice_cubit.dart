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
    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      final correctIndexes = state.correctOptionsIndices;
      final selectedIndexes = state.selectedAnswersIndices;
      final correctCount = correctIndexes.length;
      final selectedCount = selectedIndexes.length;
      final score = (selectedCount / correctCount) * 100;
      return score.toInt();
    }

    final correctIndex = state.correctOptionsIndices.first;
    final selectedIndex = state.selectedAnswerIndex;
    final score = (selectedIndex == correctIndex ? 100 : 0);
    return score;
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }
}
