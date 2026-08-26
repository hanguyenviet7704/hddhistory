part of '../../coach.dart';

/// Owns nothing but "does the bubble belong here, and does it have a dot".
///
/// Separate from [CoachCubit] because its lifetime is different: the bubble
/// question is asked every time Home becomes active, while a conversation is a
/// short-lived thing that starts when somebody taps.
@injectable
class CoachBubbleCubit extends Cubit<CoachBubbleState> {
  final GetCoachBubbleUseCase _getBubble;

  CoachBubbleCubit(this._getBubble) : super(const CoachBubbleState());

  /// Refresh for a door.
  ///
  /// Failures leave the bubble HIDDEN rather than surfacing anything. This is
  /// an optional overlay on a screen that works without it — an error toast
  /// about a coach nobody asked for would be worse than its absence.
  Future<void> refresh({
    required CoachEntry entry,
    String? lessonId,
    int? tzOffsetMinutes,
  }) async {
    final offset = tzOffsetMinutes ?? DateTime.now().timeZoneOffset.inMinutes;

    final result = await _getBubble(
      entry: entry,
      lessonId: lessonId,
      tzOffsetMinutes: offset,
    ).run();

    result.match(
      (_) => emit(const CoachBubbleState(resolved: true)),
      (bubble) => emit(
        CoachBubbleState(
          visible: bubble.visible,
          dot: bubble.dot,
          teaser: bubble.teaser,
          teaserKey: bubble.teaserKey,
          resolved: true,
        ),
      ),
    );
  }

  /// Called when a sheet closes: the dot and the teaser are almost certainly
  /// stale now, and re-asking is one small call.
  Future<void> invalidate({
    required CoachEntry entry,
    String? lessonId,
  }) => refresh(entry: entry, lessonId: lessonId);
}
