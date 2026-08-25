part of '../../coach.dart';

@freezed
abstract class CoachBubbleState with _$CoachBubbleState {
  const factory CoachBubbleState({
    @Default(false) bool visible,
    @Default(false) bool dot,
    String? teaser,

    /// True once a fetch has come back, so the bubble does not flash in on
    /// first paint before we know whether it belongs there.
    @Default(false) bool resolved,
  }) = _CoachBubbleState;
}
