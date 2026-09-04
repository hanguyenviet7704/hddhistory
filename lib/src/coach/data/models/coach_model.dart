part of '../../coach.dart';

/// Whether the bubble renders, and whether it carries the dot.
///
/// The dot is decided entirely by the server — there is exactly one situation
/// in the whole app that earns it (Home, with a commitment waiting) and keeping
/// that judgement off the client is what stops it drifting into "a dot whenever
/// something might be interesting".
@freezed
abstract class CoachBubbleModel with _$CoachBubbleModel {
  const factory CoachBubbleModel({
    @Default(false) bool visible,
    @Default(false) bool dot,
    String? teaser,

    /// ④ — a fixed teaser as a slang key, when there are no reader's words.
    String? teaserKey,
  }) = _CoachBubbleModel;

  factory CoachBubbleModel.fromJson(Map<String, dynamic> json) => _$CoachBubbleModelFromJson(json);
}

/// One selectable option.
///
/// [label] is present only for options built from data (a habit title). Fixed
/// options carry no label at all — their words live in `coach.yaml` in five
/// languages, and shipping them from the server would put the same sentence in
/// two places.
@freezed
abstract class CoachChoiceModel with _$CoachChoiceModel {
  const factory CoachChoiceModel({
    @Default('') String value,
    String? label,

    /// Luồng 1 — lit because the app already holds this answer.
    @Default(false) bool selected,
  }) = _CoachChoiceModel;

  factory CoachChoiceModel.fromJson(Map<String, dynamic> json) => _$CoachChoiceModelFromJson(json);
}

@freezed
abstract class CoachColumnsModel with _$CoachColumnsModel {
  const factory CoachColumnsModel({
    @Default(<String>[]) List<String> left,
    @Default(<String>[]) List<String> right,
  }) = _CoachColumnsModel;

  factory CoachColumnsModel.fromJson(Map<String, dynamic> json) => _$CoachColumnsModelFromJson(json);
}

@freezed
abstract class CoachHotlineModel with _$CoachHotlineModel {
  const factory CoachHotlineModel({
    @Default('') String label,
    @Default('') String number,
  }) = _CoachHotlineModel;

  factory CoachHotlineModel.fromJson(Map<String, dynamic> json) => _$CoachHotlineModelFromJson(json);
}

@freezed
abstract class CoachKeypointModel with _$CoachKeypointModel {
  const factory CoachKeypointModel({
    @Default('') String id,
    @Default('') String title,
    String? courseId,
    String? courseTitle,
    String? courseImage,
  }) = _CoachKeypointModel;

  factory CoachKeypointModel.fromJson(Map<String, dynamic> json) => _$CoachKeypointModelFromJson(json);
}

@freezed
abstract class CoachSuggestedPlanModel with _$CoachSuggestedPlanModel {
  const factory CoachSuggestedPlanModel({
    @Default('') String context,
    @Default('') String action,
  }) = _CoachSuggestedPlanModel;

  factory CoachSuggestedPlanModel.fromJson(Map<String, dynamic> json) => _$CoachSuggestedPlanModelFromJson(json);
}

@freezed
abstract class CoachShrinkModel with _$CoachShrinkModel {
  const factory CoachShrinkModel({
    @Default('') String context,
    @Default('') String action,
  }) = _CoachShrinkModel;

  factory CoachShrinkModel.fromJson(Map<String, dynamic> json) => _$CoachShrinkModelFromJson(json);
}

@freezed
abstract class CoachCourseCardModel with _$CoachCourseCardModel {
  const factory CoachCourseCardModel({
    @Default('') String courseId,
    @Default('') String title,
    String? image,
    String? habitTitle,
    String? author,
    int? viewCount,

    /// Why this course — a slang key, and the habit title it quotes.
    String? reasonKey,
    Map<String, String>? reasonArgs,
  }) = _CoachCourseCardModel;

  factory CoachCourseCardModel.fromJson(Map<String, dynamic> json) => _$CoachCourseCardModelFromJson(json);
}

/// One rubric criterion as it was scored — tầng 4 "Reflect".
@freezed
abstract class CoachScoreCriterionModel with _$CoachScoreCriterionModel {
  const factory CoachScoreCriterionModel({
    @Default('') String key,

    /// Already in the reader's language — the server resolves it from the skill.
    @Default('') String label,
    @Default(0) num score,
    String? note,
  }) = _CoachScoreCriterionModel;

  factory CoachScoreCriterionModel.fromJson(Map<String, dynamic> json) => _$CoachScoreCriterionModelFromJson(json);
}

/// The running skill number for one habit, over the last few scored scenes.
@freezed
abstract class CoachSkillScoreModel with _$CoachSkillScoreModel {
  const factory CoachSkillScoreModel({
    /// 0–100. Null on a reader's very first scored scene.
    num? score,
    @Default(0) int scenes,
    @Default(1) int level,

    /// Newer half minus older half, in points of 10. Null until there is enough.
    num? trend,
  }) = _CoachSkillScoreModel;

  factory CoachSkillScoreModel.fromJson(Map<String, dynamic> json) => _$CoachSkillScoreModelFromJson(json);
}

/// Tầng 4 — the rubric card for the scene just finished.
@freezed
abstract class CoachSceneScoreModel with _$CoachSceneScoreModel {
  const factory CoachSceneScoreModel({
    @Default(<CoachScoreCriterionModel>[]) List<CoachScoreCriterionModel> criteria,
    @Default(0) num overall,
    String? strength,
    String? improve,
    String? tip,

    /// Their own answer rewritten to do the job better. Null when it needed none.
    String? betterPhrasing,
    @Default(1) int level,
    @Default(false) bool retryAvailable,
    CoachSkillScoreModel? skill,
  }) = _CoachSceneScoreModel;

  factory CoachSceneScoreModel.fromJson(Map<String, dynamic> json) => _$CoachSceneScoreModelFromJson(json);
}

/// The scene broken into the parts the app shows as separate bubbles.
@freezed
abstract class CoachSceneModel with _$CoachSceneModel {
  const factory CoachSceneModel({
    String? habit,
    @Default('') String setup,
    String? question,
  }) = _CoachSceneModel;

  factory CoachSceneModel.fromJson(Map<String, dynamic> json) => _$CoachSceneModelFromJson(json);
}

/// Thanh habit — the habit this session is about, for the chip at the top.
@freezed
abstract class CoachHabitChipModel with _$CoachHabitChipModel {
  const factory CoachHabitChipModel({
    @Default('') String id,
    @Default('') String title,
  }) = _CoachHabitChipModel;

  factory CoachHabitChipModel.fromJson(Map<String, dynamic> json) => _$CoachHabitChipModelFromJson(json);
}

@freezed
abstract class CoachUiModel with _$CoachUiModel {
  const factory CoachUiModel({
    @Default('text') String kind,
    @Default(<CoachChoiceModel>[]) List<CoachChoiceModel> choices,
    CoachColumnsModel? columns,
    @Default(true) bool rejectAvailable,
    CoachHabitChipModel? habit,
    String? situation,
    CoachSceneModel? scene,
    @Default(<String>[]) List<String> samples,
    @Default(<CoachHotlineModel>[]) List<CoachHotlineModel> hotlines,
    @Default(<CoachKeypointModel>[]) List<CoachKeypointModel> keypoints,
    @Default(false) bool escapeAvailable,
    CoachShrinkModel? shrink,
    CoachCourseCardModel? course,
    CoachSuggestedPlanModel? suggested,
    CoachSceneScoreModel? score,
    @Default(true) bool allowNewSession,

    /// Luồng 5/6 — QUIZ_IN_CHAT: questions still to ask, the current one included.
    int? quizRemaining,

    /// Luồng 2 — `runQuiz` · `nextKeypoint`: something the app does on this step.
    String? action,

    /// Luồng 1 — where the onboarding stands; null outside it.
    CoachOnboardModel? onboard,
  }) = _CoachUiModel;

  factory CoachUiModel.fromJson(Map<String, dynamic> json) => _$CoachUiModelFromJson(json);
}

/// Luồng 1 — the progress strip's numbers and whether "Bỏ qua" is offered.
@freezed
abstract class CoachOnboardModel with _$CoachOnboardModel {
  const factory CoachOnboardModel({
    @Default(0) int step,
    @Default(0) int total,
    @Default(true) bool skippable,
  }) = _CoachOnboardModel;

  factory CoachOnboardModel.fromJson(Map<String, dynamic> json) => _$CoachOnboardModelFromJson(json);
}

@freezed
abstract class CoachCourseInviteModel with _$CoachCourseInviteModel {
  const factory CoachCourseInviteModel({
    @Default('') String courseId,
    @Default('') String title,
  }) = _CoachCourseInviteModel;

  factory CoachCourseInviteModel.fromJson(Map<String, dynamic> json) => _$CoachCourseInviteModelFromJson(json);
}

@freezed
abstract class CoachReplayModel with _$CoachReplayModel {
  const factory CoachReplayModel({
    @Default(false) bool isCoach,
    @Default('') String text,

    /// One drawn exchange: what was said or tapped, and the pieces the Coach's
    /// side is rendered from — fixed lines as KEYS, re-rendered in the current
    /// language. A `divider` item marks where one session ended.
    String? at,
    String? step,
    String? userLine,
    String? reply,
    String? speaker,
    String? noteKey,
    String? promptKey,
    Map<String, String>? promptArgs,
    String? situation,
    CoachSceneModel? scene,
    CoachDividerModel? divider,
  }) = _CoachReplayModel;

  factory CoachReplayModel.fromJson(Map<String, dynamic> json) => _$CoachReplayModelFromJson(json);
}

/// What one turn returns.
///
/// [reply] and [promptKey] never both carry a value. That split is the whole
/// i18n contract: a generated line arrives already written in the reader's
/// language and is shown as-is; a fixed line arrives as a key and is rendered
/// from slang. Neither ever travels the other's road.
/// The line between two sessions in the replay: when, and at which door.
@freezed
abstract class CoachDividerModel with _$CoachDividerModel {
  const factory CoachDividerModel({
    @Default('') String at,
    @Default('') String entry,
  }) = _CoachDividerModel;

  factory CoachDividerModel.fromJson(Map<String, dynamic> json) => _$CoachDividerModelFromJson(json);
}

@freezed
abstract class CoachTurnModel with _$CoachTurnModel {
  const factory CoachTurnModel({
    @Default('') String sessionId,
    @Default('') String step,
    String? reply,
    String? promptKey,
    Map<String, String>? promptArgs,
    String? noteKey,

    /// Tầng 3 — the reply was the scene's other person talking, by name.
    String? speaker,
    String? persona,
    @Default(CoachUiModel()) CoachUiModel ui,
    CoachCourseInviteModel? courseInvite,
    @Default(false) bool ended,

    /// The exchange so far — sent only when an existing session is resumed.
    @Default(<CoachReplayModel>[]) List<CoachReplayModel> replay,

    /// The session was picked back up: its current lines are already in `replay`.
    @Default(false) bool resumed,

    /// A door whose guards said to stay quiet. Not an error.
    @Default(false) bool silent,
    String? reasonKey,

    /// Luồng 6 — whether ⟨Đóng⟩ may plead once for this reader.
    @Default(true) bool exitPlea,
  }) = _CoachTurnModel;

  factory CoachTurnModel.fromJson(Map<String, dynamic> json) => _$CoachTurnModelFromJson(json);
}

/// A spoken turn, already turned into words. The audio never leaves the request.
@freezed
abstract class CoachTranscriptModel with _$CoachTranscriptModel {
  const factory CoachTranscriptModel({
    @Default('') String text,
  }) = _CoachTranscriptModel;

  factory CoachTranscriptModel.fromJson(Map<String, dynamic> json) => _$CoachTranscriptModelFromJson(json);
}
