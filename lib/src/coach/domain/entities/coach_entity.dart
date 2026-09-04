part of '../../coach.dart';

/// Which composer the sheet renders. Mirrors the server's `CoachUiKind` — the
/// client switches on this alone and owns no step logic of its own.
enum CoachUiKind {
  chips,
  text,

  /// Free text the reader may also skip — the story step.
  textSkippable,

  /// Free text PLUS the two depth pills — the "Bạn muốn chia sẻ thêm không?"
  /// step. Both, because the pills are shortcuts and the main road is the
  /// reader simply typing on.
  depth,

  /// Bộ điều phối — free text, up to two task pills, and the way to stop.
  hub,
  twoCols,
  nextAction,
  closing,

  /// The shrunk commitment as an editable draft, accept or keep.
  shrink,
  plan,
  schedule,

  /// One course with its three ways out drawn on the card.
  courseCard,

  /// Tầng 4 — the rubric card: bars, one strength, one thing to sharpen, a
  /// better phrasing to borrow, and "thử lại tình huống này".
  sceneScore,
  rating,

  /// The closing line, then two equal buttons: stop · new session.
  nextSession,
  end,
  safety;

  static CoachUiKind fromRaw(String raw) {
    switch (raw) {
      case 'chips':
        return CoachUiKind.chips;
      case 'text_skippable':
        return CoachUiKind.textSkippable;
      case 'depth':
        return CoachUiKind.depth;
      case 'hub':
        return CoachUiKind.hub;
      case 'two_cols':
        return CoachUiKind.twoCols;
      case 'next_action':
        return CoachUiKind.nextAction;
      case 'scene_score':
        return CoachUiKind.sceneScore;
      case 'closing':
        return CoachUiKind.closing;
      case 'shrink':
        return CoachUiKind.shrink;
      case 'plan':
        return CoachUiKind.plan;
      case 'schedule':
        return CoachUiKind.schedule;
      case 'course_card':
        return CoachUiKind.courseCard;
      case 'rating':
        return CoachUiKind.rating;
      case 'next_session':
        return CoachUiKind.nextSession;
      case 'end':
        return CoachUiKind.end;
      case 'safety':
        return CoachUiKind.safety;
      default:
        return CoachUiKind.text;
    }
  }
}

/// Where the bubble is being asked about.
enum CoachEntry {
  lesson,
  habit,
  home;

  String get raw => name;
}

class CoachBubbleEntity {
  final bool visible;
  final bool dot;
  final String? teaser;

  /// ④ — a fixed teaser as a slang key. Rendered when [teaser] is null.
  final String? teaserKey;

  const CoachBubbleEntity({
    this.visible = false,
    this.dot = false,
    this.teaser,
    this.teaserKey,
  });

  static const hidden = CoachBubbleEntity();
}

class CoachChoiceEntity {
  final String value;
  final String? label;

  /// Luồng 1 — drawn filled: the app already knows this is the answer.
  final bool selected;

  const CoachChoiceEntity({required this.value, this.label, this.selected = false});
}

/// Luồng 1 — the onboarding's position: "Câu 3/8" and whether it can be skipped.
class CoachOnboardEntity {
  final int step;
  final int total;
  final bool skippable;

  const CoachOnboardEntity({required this.step, required this.total, required this.skippable});
}

/// Nhịp 4 — a keypoint the closing beat points at. Read from the catalogue,
/// never generated, and never more than two.
class CoachKeypointEntity {
  final String id;
  final String title;

  /// The published course a tap on the row opens — the head of the same
  /// ranking ③C's invite uses. Empty when no published course teaches the
  /// habit's keypoints: the row then reads without linking.
  final String courseId;
  final String courseTitle;
  final String courseImage;

  const CoachKeypointEntity({
    required this.id,
    required this.title,
    this.courseId = '',
    this.courseTitle = '',
    this.courseImage = '',
  });
}

/// PLAN — a pre-fill for the commitment form, carried from a scene just
/// practised. Both fields editable; empty when no scene led here.
class CoachSuggestedPlanEntity {
  final String context;
  final String action;

  const CoachSuggestedPlanEntity({this.context = '', this.action = ''});

  bool get isEmpty => context.isEmpty && action.isEmpty;
}

/// ②A — the smaller commitment the Coach proposed. A draft until the reader taps.
class CoachShrinkEntity {
  final String context;
  final String action;

  const CoachShrinkEntity({required this.context, required this.action});
}

/// The one course the tail offers — read from the library, never generated.
class CoachCourseCardEntity {
  final String courseId;
  final String title;
  final String image;
  final String habitTitle;

  /// Drawn on the card as the course rail draws them; blank hides the chip.
  final String author;
  final int? viewCount;

  /// Why THIS course — a slang key and the habit title it quotes. A fact about
  /// the reader ("you keep stopping at X", "you saved this"), never a model's
  /// opinion. Null when the server had no reason to give.
  final String? reasonKey;
  final Map<String, String> reasonArgs;

  const CoachCourseCardEntity({
    required this.courseId,
    required this.title,
    this.image = '',
    this.habitTitle = '',
    this.author = '',
    this.viewCount,
    this.reasonKey,
    this.reasonArgs = const {},
  });
}

class CoachHotlineEntity {
  final String label;
  final String number;

  const CoachHotlineEntity({required this.label, required this.number});
}

/// One rubric criterion as it was scored — tầng 4 "Reflect".
class CoachScoreCriterionEntity {
  final String key;

  /// Already in the reader's language: the server resolves it from the skill.
  final String label;
  final double score;
  final String? note;

  const CoachScoreCriterionEntity({
    required this.key,
    required this.label,
    required this.score,
    this.note,
  });
}

/// The running skill number for one habit, over the last few scored scenes.
class CoachSkillScoreEntity {
  /// 0–100. Null on the reader's very first scored scene — a 0 would read as a
  /// verdict rather than a measurement.
  final int? score;
  final int scenes;

  /// The difficulty the NEXT scene will aim for, after this score moved it.
  final int level;

  /// Newer half minus older half, in points of 10. Null until there is enough.
  final double? trend;

  const CoachSkillScoreEntity({
    this.score,
    this.scenes = 0,
    this.level = 1,
    this.trend,
  });
}

/// Tầng 4 — the rubric card shown when a scored scene is finished.
class CoachSceneScoreEntity {
  final List<CoachScoreCriterionEntity> criteria;

  /// Mean of the criteria, 0–10.
  final double overall;
  final String? strength;
  final String? improve;
  final String? tip;

  /// Their own answer rewritten to do the job better. Null when it needed none.
  final String? betterPhrasing;

  /// Difficulty of the scene that was scored, 1–5.
  final int level;
  final bool retryAvailable;
  final CoachSkillScoreEntity? skill;

  const CoachSceneScoreEntity({
    this.criteria = const [],
    this.overall = 0,
    this.strength,
    this.improve,
    this.tip,
    this.betterPhrasing,
    this.level = 1,
    this.retryAvailable = false,
    this.skill,
  });
}

/// The scene, split so the thread shows it as several short bubbles instead of
/// one block. Built server-side: the app has no habit title at this step, and a
/// client-side sentence splitter would drift between platforms.
class CoachSceneEntity {
  /// The habit being practised. Null at ①, whose intro already names it.
  final String? habit;
  final String setup;

  /// The closing question, shown last and on its own. Null if the scene had none.
  final String? question;

  const CoachSceneEntity({this.habit, required this.setup, this.question});
}

class CoachUiEntity {
  final CoachUiKind kind;
  final List<CoachChoiceEntity> choices;
  final List<String> columnLeft;
  final List<String> columnRight;

  /// Nhịp 3 — whether ⑤ "Không đúng với mình" is still offered.
  final bool rejectAvailable;

  /// Thanh habit — the habit under discussion, shown as a chip with "đổi" from
  /// the moment it is certain. Null before that, and never spoken out loud.
  final CoachHabitChipEntity? habit;
  final String? situation;

  /// The same scene, split into habit · setup · question for separate bubbles.
  final CoachSceneEntity? scene;

  /// Two answers the reader can tap instead of typing. Empty is normal.
  final List<String> samples;
  final List<CoachHotlineEntity> hotlines;
  final List<CoachKeypointEntity> keypoints;
  final bool escapeAvailable;
  final CoachShrinkEntity? shrink;
  final CoachCourseCardEntity? course;

  /// PLAN — pre-fill for the commitment form from the scene just practised.
  final CoachSuggestedPlanEntity? suggested;

  /// SCENE_SCORE — the rubric read on the scene just finished.
  final CoachSceneScoreEntity? score;

  /// NEXT_SESSION — false on a low mood-end: only "Dừng" remains.
  final bool allowNewSession;

  /// QUIZ_IN_CHAT — questions still to ask (luồng 5); the plea counts them (luồng 6).
  final int? quizRemaining;

  /// Luồng 2 — `runQuiz` · `nextKeypoint`: something the app does on this step.
  final String? action;

  /// Luồng 1 — non-null only while the onboarding runs.
  final CoachOnboardEntity? onboard;

  const CoachUiEntity({
    this.kind = CoachUiKind.text,
    this.choices = const [],
    this.columnLeft = const [],
    this.columnRight = const [],
    this.rejectAvailable = true,
    this.habit,
    this.situation,
    this.scene,
    this.samples = const [],
    this.hotlines = const [],
    this.keypoints = const [],
    this.escapeAvailable = false,
    this.shrink,
    this.course,
    this.suggested,
    this.score,
    this.allowNewSession = true,
    this.quizRemaining,
    this.action,
    this.onboard,
  });
}

/// The habit the chip names — id for the picker, title read from the DB.
class CoachHabitChipEntity {
  final String id;
  final String title;

  const CoachHabitChipEntity({required this.id, required this.title});
}

class CoachCourseInviteEntity {
  final String courseId;
  final String title;

  const CoachCourseInviteEntity({required this.courseId, required this.title});
}

/// One item of the replay: a drawn exchange, or the divider before a session.
class CoachReplayEntity {
  final DateTime? at;
  final String? userLine;
  final String? reply;
  final String? speaker;
  final String? noteKey;
  final String? promptKey;
  final Map<String, String> promptArgs;
  final String? situation;
  final CoachSceneEntity? scene;
  final CoachDividerEntity? divider;

  const CoachReplayEntity({
    this.at,
    this.userLine,
    this.reply,
    this.speaker,
    this.noteKey,
    this.promptKey,
    this.promptArgs = const {},
    this.situation,
    this.scene,
    this.divider,
  });
}

class CoachDividerEntity {
  final DateTime at;
  final String entry;

  const CoachDividerEntity({required this.at, required this.entry});
}

class CoachTurnEntity {
  final String sessionId;
  final String step;

  /// Written by the model, already in the reader's language. Show as-is.
  final String? reply;

  /// A slang key for a fixed line. Render through `context.l10n`.
  final String? promptKey;

  /// The reader's own words to fill the fixed line with — the commitment at
  /// the check-in, its context, the reminder time in the closing line.
  final Map<String, String> promptArgs;

  /// A fixed line shown BEFORE the step's own — "cái hẹn này mình tạm cất đi nhé".
  final String? noteKey;

  /// Tầng 3 — the reply was the scene's other person talking, under this name.
  /// Null on every ordinary Coach turn.
  final String? speaker;

  /// The voice in force, pre-lit from last time; changeable from the header.
  final String persona;

  final CoachUiEntity ui;
  final CoachCourseInviteEntity? courseInvite;
  final bool ended;

  /// The thread to draw before this response's own lines: earlier sessions
  /// (each behind a divider), then — on resume — this session so far.
  final List<CoachReplayEntity> replay;

  /// Picked back up: the current step's lines are already in [replay], so the
  /// sheet draws the replay and nothing more.
  final bool resumed;

  /// The door decided to stay quiet. The sheet never opens; nothing is wrong.
  final bool silent;
  final String? reasonKey;

  /// Luồng 6 — whether ⟨Đóng⟩ may plead once. Off after two declines in a row.
  final bool exitPlea;

  const CoachTurnEntity({
    this.sessionId = '',
    this.step = '',
    this.reply,
    this.promptKey,
    this.promptArgs = const {},
    this.noteKey,
    this.speaker,
    this.persona = 'friend',
    this.ui = const CoachUiEntity(),
    this.courseInvite,
    this.ended = false,
    this.replay = const [],
    this.resumed = false,
    this.silent = false,
    this.reasonKey,
    this.exitPlea = true,
  });
}

extension CoachBubbleModelX on CoachBubbleModel {
  CoachBubbleEntity toEntity() => CoachBubbleEntity(
    visible: visible,
    dot: dot,
    teaser: (teaser?.trim().isEmpty ?? true) ? null : teaser,
    teaserKey: (teaserKey?.trim().isEmpty ?? true) ? null : teaserKey,
  );
}

extension CoachTurnModelX on CoachTurnModel {
  CoachTurnEntity toEntity() => CoachTurnEntity(
    sessionId: sessionId,
    step: step,
    reply: (reply?.trim().isEmpty ?? true) ? null : reply,
    promptKey: (promptKey?.trim().isEmpty ?? true) ? null : promptKey,
    promptArgs: promptArgs ?? const {},
    noteKey: (noteKey?.trim().isEmpty ?? true) ? null : noteKey,
    speaker: (speaker?.trim().isEmpty ?? true) ? null : speaker,
    persona: (persona?.trim().isEmpty ?? true) ? 'friend' : persona!,
    resumed: resumed,
    replay: replay.map((r) => r.toEntity()).toList(),
    ui: CoachUiEntity(
      kind: CoachUiKind.fromRaw(ui.kind),
      choices: ui.choices.map((c) => CoachChoiceEntity(value: c.value, label: c.label, selected: c.selected)).toList(),
      columnLeft: ui.columns?.left ?? const [],
      columnRight: ui.columns?.right ?? const [],
      rejectAvailable: ui.rejectAvailable,
      habit: ui.habit == null || ui.habit!.title.trim().isEmpty ? null : CoachHabitChipEntity(id: ui.habit!.id, title: ui.habit!.title),
      situation: (ui.situation?.trim().isEmpty ?? true) ? null : ui.situation,
      // A scene may legitimately carry ONLY its question now — the second
      // stage arrives split (body in `situation`, question here), and a
      // mapping that required a setup silently swallowed that question on
      // screen ("thiếu mất bạn làm gì", owner on-device 2026-08-28). Dropped
      // only when it carries nothing at all.
      scene: ui.scene == null || (ui.scene!.setup.trim().isEmpty && (ui.scene!.question?.trim().isEmpty ?? true) && (ui.scene!.habit?.trim().isEmpty ?? true))
          ? null
          : CoachSceneEntity(
              habit: (ui.scene!.habit?.trim().isEmpty ?? true) ? null : ui.scene!.habit,
              setup: ui.scene!.setup,
              question: (ui.scene!.question?.trim().isEmpty ?? true) ? null : ui.scene!.question,
            ),
      samples: ui.samples,
      hotlines: ui.hotlines.map((h) => CoachHotlineEntity(label: h.label, number: h.number)).toList(),
      // Was silently missing: the server's nhịp-4 suggestion arrived, got
      // deserialized, and died right here — the entity always said [].
      keypoints: ui.keypoints
          .map(
            (k) => CoachKeypointEntity(
              id: k.id,
              title: k.title,
              courseId: k.courseId ?? '',
              courseTitle: k.courseTitle ?? '',
              courseImage: k.courseImage ?? '',
            ),
          )
          .toList(),
      escapeAvailable: ui.escapeAvailable,
      quizRemaining: ui.quizRemaining,
      action: (ui.action?.trim().isEmpty ?? true) ? null : ui.action,
      onboard: ui.onboard == null || ui.onboard!.total <= 0 ? null : CoachOnboardEntity(step: ui.onboard!.step, total: ui.onboard!.total, skippable: ui.onboard!.skippable),
      score: ui.score == null || ui.score!.criteria.isEmpty
          ? null
          : CoachSceneScoreEntity(
              criteria: ui.score!.criteria
                  .map(
                    (c) => CoachScoreCriterionEntity(
                      key: c.key,
                      label: c.label,
                      score: c.score.toDouble(),
                      note: (c.note?.trim().isEmpty ?? true) ? null : c.note,
                    ),
                  )
                  .toList(),
              overall: ui.score!.overall.toDouble(),
              strength: (ui.score!.strength?.trim().isEmpty ?? true) ? null : ui.score!.strength,
              improve: (ui.score!.improve?.trim().isEmpty ?? true) ? null : ui.score!.improve,
              tip: (ui.score!.tip?.trim().isEmpty ?? true) ? null : ui.score!.tip,
              betterPhrasing: (ui.score!.betterPhrasing?.trim().isEmpty ?? true) ? null : ui.score!.betterPhrasing,
              level: ui.score!.level,
              retryAvailable: ui.score!.retryAvailable,
              skill: ui.score!.skill == null
                  ? null
                  : CoachSkillScoreEntity(
                      score: ui.score!.skill!.score?.round(),
                      scenes: ui.score!.skill!.scenes,
                      level: ui.score!.skill!.level,
                      trend: ui.score!.skill!.trend?.toDouble(),
                    ),
            ),
      shrink: ui.shrink == null ? null : CoachShrinkEntity(context: ui.shrink!.context, action: ui.shrink!.action),
      course: ui.course == null || ui.course!.courseId.isEmpty
          ? null
          : CoachCourseCardEntity(
              courseId: ui.course!.courseId,
              title: ui.course!.title,
              image: ui.course!.image ?? '',
              habitTitle: ui.course!.habitTitle ?? '',
              author: ui.course!.author ?? '',
              viewCount: ui.course!.viewCount,
              reasonKey: (ui.course!.reasonKey?.trim().isEmpty ?? true) ? null : ui.course!.reasonKey,
              reasonArgs: ui.course!.reasonArgs ?? const {},
            ),
      suggested: ui.suggested == null
          ? null
          : CoachSuggestedPlanEntity(
              context: ui.suggested!.context,
              action: ui.suggested!.action,
            ),
      allowNewSession: ui.allowNewSession,
    ),
    courseInvite: courseInvite == null
        ? null
        : CoachCourseInviteEntity(
            courseId: courseInvite!.courseId,
            title: courseInvite!.title,
          ),
    ended: ended,
    exitPlea: exitPlea,
    silent: silent,
    reasonKey: reasonKey,
  );
}

extension CoachReplayModelX on CoachReplayModel {
  /// Older servers sent only `isCoach` + `text`; those still read as one line.
  CoachReplayEntity toEntity() {
    String? clean(String? v) => (v?.trim().isEmpty ?? true) ? null : v;
    final d = divider;
    final dividerAt = d == null ? null : DateTime.tryParse(d.at);
    final legacy = clean(text);

    return CoachReplayEntity(
      at: DateTime.tryParse(at ?? ''),
      userLine: clean(userLine) ?? (legacy != null && !isCoach ? legacy : null),
      reply: clean(reply) ?? (legacy != null && isCoach && clean(userLine) == null ? legacy : null),
      speaker: clean(speaker),
      noteKey: clean(noteKey),
      promptKey: clean(promptKey),
      promptArgs: promptArgs ?? const {},
      situation: clean(situation),
      scene: scene == null || (scene!.setup.trim().isEmpty && clean(scene!.question) == null && clean(scene!.habit) == null)
          ? null
          : CoachSceneEntity(habit: clean(scene!.habit), setup: scene!.setup, question: clean(scene!.question)),
      divider: d == null || dividerAt == null ? null : CoachDividerEntity(at: dividerAt, entry: d.entry),
    );
  }
}
