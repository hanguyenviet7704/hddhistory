part of '../../../exercise.dart';

enum ChoiceStatus { initial, loading, success, failure }

@freezed
sealed class ChoiceState with _$ChoiceState {
  const factory ChoiceState({
    @Default(ChoiceStatus.initial) ChoiceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default(null) OptionEntity? selectedAnswer,
    @Default({}) Set<OptionEntity> selectedAnswers,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
  }) = _ChoiceState;

  factory ChoiceState.initial() => const ChoiceState();
}

extension ChoiceStateExtension on ChoiceState {
  List<OptionEntity> get answerOptions => question.options;
  List<OptionEntity> get correctOptions => question.options.where((option) => option.isCorrect).toList();
}
