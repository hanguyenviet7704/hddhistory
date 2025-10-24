part of '../../../exercise.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void loadQuestionData(QuestionEntity question) => emit(state.copyWith(question: question));

  void loadQuestion(ChoiceQuestion question) {
    emit(
      state.copyWith(
        currentQuestion: question,
        selectedAnswerIndex: -1,
        selectedAnswers: {},
        hasChecked: false,
        isCorrect: false,
      ),
    );
  }

  void selectAnswer(int index) {
    if (state.hasChecked) return;

    if (state.currentQuestion?.isMultiChoice == true) {
      // Handle multiple choice
      final Set<int> newSelectedAnswers = Set<int>.from(state.selectedAnswers);
      if (newSelectedAnswers.contains(index)) {
        newSelectedAnswers.remove(index);
      } else {
        newSelectedAnswers.add(index);
      }
      emit(state.copyWith(selectedAnswers: newSelectedAnswers));
    } else {
      // Handle single choice
      emit(state.copyWith(selectedAnswerIndex: index));
    }
  }

  void checkAnswer() {
    if (state.currentQuestion == null) return;

    bool isCorrect = false;

    if (state.currentQuestion!.isMultiChoice) {
      // Check multiple choice answer
      if (state.selectedAnswers.isNotEmpty) {
        final correctSet = state.currentQuestion!.correctAnswersIndices ?? {};
        isCorrect = state.selectedAnswers.length == correctSet.length && state.selectedAnswers.every((index) => correctSet.contains(index));
      }
    } else {
      // Check single choice answer
      if (state.selectedAnswerIndex != -1) {
        isCorrect = state.selectedAnswerIndex == state.currentQuestion!.correctAnswerIndex;
      }
    }

    emit(
      state.copyWith(
        hasChecked: true,
        isCorrect: isCorrect,
      ),
    );
  }

  void reset() {
    emit(ChoiceState.initial());
  }
}
