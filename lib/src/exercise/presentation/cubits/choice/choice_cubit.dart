part of '../../../exercise.dart';

@lazySingleton
class ChoiceCubit extends Cubit<ChoiceState> {
  ChoiceCubit() : super(ChoiceState.initial());

  void loadQuestionData(QuestionEntity question) => emit(state.copyWith(question: question));

  void loadQuestion(ChoiceQuestion question) {
    emit(
      state.copyWith(
        selectedAnswer: null,
        selectedAnswers: {},
        hasChecked: false,
        isCorrect: false,
      ),
    );
  }

  void selectAnswer(OptionEntity option) {
    if (state.hasChecked) return;

    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      // Handle multiple choice
      final Set<OptionEntity> newSelectedAnswers = Set<OptionEntity>.from(state.selectedAnswers);
      if (newSelectedAnswers.contains(option)) {
        newSelectedAnswers.remove(option);
      } else {
        newSelectedAnswers.add(option);
      }
      emit(state.copyWith(selectedAnswers: newSelectedAnswers));
      return;
    }

    // Handle single choice
    emit(state.copyWith(selectedAnswer: option));
  }

  void checkAnswer() {
    if (state.question.id == 0) return;

    bool isCorrect = false;

    if (state.question.type == QuestionTypeEnum.multipleChoice) {
      // Check multiple choice answer
      if (state.selectedAnswers.isNotEmpty) {
        Set<int> correctIndexes = state.correctOptions.map((option) => option.id).toSet();
        Set<int> selectedIndexes = state.selectedAnswers.map((option) => option.id).toSet();
        isCorrect = correctIndexes.containsAll(selectedIndexes) && selectedIndexes.containsAll(correctIndexes);
      }
    } else {
      // Check single choice answer
      if (state.selectedAnswer != null) {
        isCorrect = state.correctOptions.any((option) => state.selectedAnswers.contains(option));
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
