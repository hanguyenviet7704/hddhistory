part of '../../coach.dart';

/// Which composer the sheet renders. Mirrors the server's `CoachUiKind` — the
/// client switches on this alone and owns no step logic of its own.
enum CoachUiKind {
  chips,
  text,
  twoCols,
  nextAction,
  closing,
  plan,
  schedule,
  rating,
  end,
  safety;

  static CoachUiKind fromRaw(String raw) {
    switch (raw) {
      case 'chips':
        return CoachUiKind.chips;
      case 'two_cols':
        return CoachUiKind.twoCols;
      case 'next_action':
        return CoachUiKind.nextAction;
      case 'closing':
        return CoachUiKind.closing;
      case 'plan':
        return CoachUiKind.plan;
      case 'schedule':
        return CoachUiKind.schedule;
      case 'rating':
        return CoachUiKind.rating;
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

  const CoachBubbleEntity({
    this.visible = false,
    this.dot = false,
    this.teaser,
  });

  static const hidden = CoachBubbleEntity();
}

class CoachChoiceEntity {
  final String value;
  final String? label;

  const CoachChoiceEntity({required this.value, this.label});
}

/// Nhịp 4 — a keypoint the closing beat points at. Read from the catalogue,
/// never generated, and never more than two.
class CoachKeypointEntity {
  final String id;
  final String title;

  const CoachKeypointEntity({required this.id, required this.title});
}

class CoachHotlineEntity {
  final String label;
  final String number;

  const CoachHotlineEntity({required this.label, required this.number});
}

class CoachUiEntity {
  final CoachUiKind kind;
  final List<CoachChoiceEntity> choices;
  final List<String> columnLeft;
  final List<String> columnRight;
  final String? situation;

  /// Two answers the reader can tap instead of typing. Empty is normal.
  final List<String> samples;
  final List<CoachHotlineEntity> hotlines;
  final List<CoachKeypointEntity> keypoints;
  final bool escapeAvailable;

  const CoachUiEntity({
    this.kind = CoachUiKind.text,
    this.choices = const [],
    this.columnLeft = const [],
    this.columnRight = const [],
    this.situation,
    this.samples = const [],
    this.hotlines = const [],
    this.keypoints = const [],
    this.escapeAvailable = false,
  });
}

class CoachCourseInviteEntity {
  final String courseId;
  final String title;

  const CoachCourseInviteEntity({required this.courseId, required this.title});
}

class CoachTurnEntity {
  final String sessionId;
  final String step;

  /// Written by the model, already in the reader's language. Show as-is.
  final String? reply;

  /// A slang key for a fixed line. Render through `context.l10n`.
  final String? promptKey;

  final CoachUiEntity ui;
  final CoachCourseInviteEntity? courseInvite;
  final bool ended;

  /// The exchange so far, when a session was resumed rather than started.
  final List<CoachMessage> replay;

  /// The door decided to stay quiet. The sheet never opens; nothing is wrong.
  final bool silent;
  final String? reasonKey;

  const CoachTurnEntity({
    this.sessionId = '',
    this.step = '',
    this.reply,
    this.promptKey,
    this.ui = const CoachUiEntity(),
    this.courseInvite,
    this.ended = false,
    this.replay = const [],
    this.silent = false,
    this.reasonKey,
  });
}

extension CoachBubbleModelX on CoachBubbleModel {
  CoachBubbleEntity toEntity() => CoachBubbleEntity(
    visible: visible,
    dot: dot,
    teaser: (teaser?.trim().isEmpty ?? true) ? null : teaser,
  );
}

extension CoachTurnModelX on CoachTurnModel {
  CoachTurnEntity toEntity() => CoachTurnEntity(
    sessionId: sessionId,
    step: step,
    reply: (reply?.trim().isEmpty ?? true) ? null : reply,
    promptKey: (promptKey?.trim().isEmpty ?? true) ? null : promptKey,
    ui: CoachUiEntity(
      kind: CoachUiKind.fromRaw(ui.kind),
      choices: ui.choices.map((c) => CoachChoiceEntity(value: c.value, label: c.label)).toList(),
      columnLeft: ui.columns?.left ?? const [],
      columnRight: ui.columns?.right ?? const [],
      situation: (ui.situation?.trim().isEmpty ?? true) ? null : ui.situation,
      samples: ui.samples,
      hotlines: ui.hotlines.map((h) => CoachHotlineEntity(label: h.label, number: h.number)).toList(),
      escapeAvailable: ui.escapeAvailable,
    ),
    courseInvite: courseInvite == null
        ? null
        : CoachCourseInviteEntity(
            courseId: courseInvite!.courseId,
            title: courseInvite!.title,
          ),
    ended: ended,
    silent: silent,
    reasonKey: reasonKey,
  );
}
