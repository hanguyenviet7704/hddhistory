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
      final pointPerCorrect = 100.0 / correctCount;

      final correctSelections = selectedIndexes.where((index) => correctIndexes.contains(index)).length;
      final wrongSelections = selectedIndexes.where((index) => !correctIndexes.contains(index)).length;

      final score = (correctSelections * pointPerCorrect) - (wrongSelections * pointPerCorrect * 0.5);

      return score.clamp(0, 100).toInt();
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
