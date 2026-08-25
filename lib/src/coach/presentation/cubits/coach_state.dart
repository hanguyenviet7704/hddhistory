part of '../../coach.dart';

enum CoachStatus { initial, opening, ready, sending, closed, failed }

/// One line in the sheet.
///
/// [isCoach] rather than a role enum because there are only ever two, and
/// [text] is already resolved: a generated line arrives written, a fixed line
/// was rendered from slang before it got here. The widget never has to know
/// which it was.
class CoachMessage {
  final bool isCoach;
  final String text;

  const CoachMessage({required this.isCoach, required this.text});
}

@freezed
abstract class CoachState with _$CoachState {
  const factory CoachState({
    @Default(CoachStatus.initial) CoachStatus status,
    @Default('') String sessionId,
    @Default('') String step,
    @Default(<CoachMessage>[]) List<CoachMessage> messages,
    @Default(CoachUiEntity()) CoachUiEntity ui,
    CoachCourseInviteEntity? courseInvite,

    /// The door stayed quiet. The sheet should not have opened.
    @Default(false) bool silent,
    String? silentReasonKey,

    /// The Coach is composing. Drives the three-dot line, and blocks input:
    /// two turns in flight would be answered against different steps.
    @Default(false) bool typing,

    /// ⑦ drag state, mirrored locally so a tap moves a line instantly.
    @Default(<String>[]) List<String> columnLeft,
    @Default(<String>[]) List<String> columnRight,
    @Default(false) bool ended,
  }) = _CoachState;
}
