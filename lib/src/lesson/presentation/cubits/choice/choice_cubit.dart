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
        isCorrect = correctIndexes == selectedIndexes;
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
      AppDI.injector.get<ExerciseCubit>().addWrongSubQuestionToLessonCubit(state.question);
    }
  }

  void toggleExplanation() {
    emit(state.copyWith(showExplanation: !state.showExplanation));
  }
}
