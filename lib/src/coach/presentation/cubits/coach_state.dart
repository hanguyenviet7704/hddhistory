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

  /// Tầng 3 — the scene's other person said this, under this name. The bubble
  /// carries the label so a roleplay turn reads as dialogue rather than as the
  /// Coach suddenly making demands. Null on every ordinary line.
  final String? speaker;

  /// A bold heading above the text, in the reader's language — "Với thói quen:",
  /// "Tôi có tình huống:". The scene arrives as several short bubbles rather than
  /// one block, and the heading is what tells them apart at a glance.
  final String? title;

  /// Render the body itself bold — the scene's closing question, which is the
  /// line being answered.
  final bool emphasis;

  const CoachMessage({
    required this.isCoach,
    required this.text,
    this.speaker,
    this.title,
    this.emphasis = false,
  });
}

@freezed
abstract class CoachState with _$CoachState {
  const factory CoachState({
    @Default(CoachStatus.initial) CoachStatus status,
    @Default('') String sessionId,

    /// Which door opened the sheet — the END button says where "Đóng" goes.
    @Default(CoachEntry.home) CoachEntry entry,
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

    /// The voice in force — mirrored here so the header can show and change it.
    @Default('friend') String persona,

    /// ⑦ drag state, mirrored locally so a tap moves a line instantly.
    @Default(<String>[]) List<String> columnLeft,
    @Default(<String>[]) List<String> columnRight,
    @Default(false) bool ended,

    /// Luồng 6 — ⟨Đóng⟩ may plead once; false once the reader declined twice in a row.
    @Default(true) bool exitPlea,
  }) = _CoachState;
}
