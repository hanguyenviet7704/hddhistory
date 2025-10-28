part of '../../../exercise.dart';

enum ArrangeTheSequenceStatus { initial, loading, success, failure }

@freezed
sealed class ArrangeTheSequenceState with _$ArrangeTheSequenceState {
  const factory ArrangeTheSequenceState({
    @Default(ArrangeTheSequenceStatus.initial) ArrangeTheSequenceStatus status,
    @Default(QuestionEntity()) QuestionEntity question,
  }) = _ArrangeTheSequenceState;

  factory ArrangeTheSequenceState.initial() => const ArrangeTheSequenceState();
}
