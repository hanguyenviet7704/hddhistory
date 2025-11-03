part of '../../../lesson.dart';

enum ArrangeTheSequenceStatus { initial, loading, success, failure }

@freezed
sealed class ArrangeTheSequenceState with _$ArrangeTheSequenceState {
  const factory ArrangeTheSequenceState({
    @Default(ArrangeTheSequenceStatus.initial) ArrangeTheSequenceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
    @Default([]) List<OptionEntity> currentItems,
    @Default(false) bool hasChecked,
    @Default(false) bool isCorrect,
    @Default(false) bool showExplanation,
  }) = _ArrangeTheSequenceState;

  factory ArrangeTheSequenceState.initial() => const ArrangeTheSequenceState();
}
