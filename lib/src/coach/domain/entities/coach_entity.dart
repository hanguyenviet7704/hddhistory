part of '../../coach.dart';

/// Which composer the sheet renders. Mirrors the server's `CoachUiKind` — the
/// client switches on this alone and owns no step logic of its own.
enum CoachUiKind {
  chips,
  text,
  /// Free text the reader may also skip — the story step.
  textSkippable,
  twoCols,
  nextAction,
  closing,
  /// The shrunk commitment as an editable draft, accept or keep.
  shrink,
  plan,
  schedule,
  /// One course with its three ways out drawn on the card.
  courseCard,
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
      case 'two_cols':
        return CoachUiKind.twoCols;
      case 'next_action':
        return CoachUiKind.nextAction;
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

  const CoachCourseCardEntity({
    required this.courseId,
    required this.title,
    this.image = '',
    this.habitTitle = '',
  });
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
  final CoachShrinkEntity? shrink;
  final CoachCourseCardEntity? course;

  /// NEXT_SESSION — false on a low mood-end: only "Dừng" remains.
  final bool allowNewSession;

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
    this.shrink,
    this.course,
    this.allowNewSession = true,
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

  /// The reader's own words to fill the fixed line with — the commitment at
  /// the check-in, its context, the reminder time in the closing line.
  final Map<String, String> promptArgs;

  /// A fixed line shown BEFORE the step's own — "cái hẹn này mình tạm cất đi nhé".
  final String? noteKey;

  /// The voice in force, pre-lit from last time; changeable from the header.
  final String persona;

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
    this.promptArgs = const {},
    this.noteKey,
    this.persona = 'friend',
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
    promptArgs: promptArgs ?? const {},
    noteKey: (noteKey?.trim().isEmpty ?? true) ? null : noteKey,
    persona: (persona?.trim().isEmpty ?? true) ? 'friend' : persona!,
    ui: CoachUiEntity(
      kind: CoachUiKind.fromRaw(ui.kind),
      choices: ui.choices.map((c) => CoachChoiceEntity(value: c.value, label: c.label)).toList(),
      columnLeft: ui.columns?.left ?? const [],
      columnRight: ui.columns?.right ?? const [],
      situation: (ui.situation?.trim().isEmpty ?? true) ? null : ui.situation,
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
      shrink: ui.shrink == null
          ? null
          : CoachShrinkEntity(context: ui.shrink!.context, action: ui.shrink!.action),
      course: ui.course == null || ui.course!.courseId.isEmpty
          ? null
          : CoachCourseCardEntity(
              courseId: ui.course!.courseId,
              title: ui.course!.title,
              image: ui.course!.image ?? '',
              habitTitle: ui.course!.habitTitle ?? '',
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
    silent: silent,
    reasonKey: reasonKey,
  );
}
