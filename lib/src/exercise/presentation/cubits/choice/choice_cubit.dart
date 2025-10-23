part of '../../../exercise.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void loadQuestion(ChoiceQuestion question) {
    emit(
      state.copyWith(
        currentQuestion: question,
        selectedAnswerIndex: -1,
        hasChecked: false,
        isCorrect: false,
      ),
    );
  }

  void selectAnswer(int index) {
    if (state.hasChecked) return;

    emit(state.copyWith(selectedAnswerIndex: index));
  }

  void checkAnswer() {
    if (state.selectedAnswerIndex == -1 || state.currentQuestion == null) return;

    final isCorrect = state.selectedAnswerIndex == state.currentQuestion!.correctAnswerIndex;

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
