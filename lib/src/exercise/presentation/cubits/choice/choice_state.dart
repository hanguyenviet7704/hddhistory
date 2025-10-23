part of '../../../exercise.dart';

enum ChoiceStatus { initial, loading, success, failure }

@freezed
sealed class ChoiceState with _$ChoiceState {
  const factory ChoiceState({
    @Default(ChoiceStatus.initial) ChoiceStatus status,
    @Default(-1) int selectedAnswerIndex,
    @Default({}) Set<int> selectedAnswers,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    ChoiceQuestion? currentQuestion,
  }) = _ChoiceState;

  factory ChoiceState.initial() => const ChoiceState();
}
