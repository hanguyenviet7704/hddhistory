part of '../../learning_import.dart';

/// Kinds of block inside a section. Only two, matching what the API generates:
/// v1 produces prose only, and every kind added here is a branch the reader has
/// to grow.
enum LessonBlockTypeEntity {
  @JsonValue('heading')
  heading,
  @JsonValue('paragraph')
  paragraph,
}

@freezed
abstract class LessonBlockEntity with _$LessonBlockEntity {
  const factory LessonBlockEntity({
    @Default(LessonBlockTypeEntity.paragraph) LessonBlockTypeEntity type,
    @Default('') String text,
  }) = _LessonBlockEntity;
}

@freezed
abstract class LessonSectionEntity with _$LessonSectionEntity {
  const factory LessonSectionEntity({
    @Default('') String title,
    @Default(<LessonBlockEntity>[]) List<LessonBlockEntity> blocks,
  }) = _LessonSectionEntity;
}

/// Whether a lesson has narration yet.
///
/// Dubbing runs as its own phase after the lesson is already saved, so this is a
/// second signal independent of the import job: the job says the lesson is
/// readable, this says it is listenable.
///
/// [failed] is an ordinary state, not an incident — the TTS provider has no SLA.
/// A lesson with no audio must render as normal, never as broken.
enum UserLessonAudioStatusEntity {
  @JsonValue('none')
  none,
  @JsonValue('processing')
  processing,
  @JsonValue('ready')
  ready,
  @JsonValue('failed')
  failed,
}

/// Where one card's narration sits inside the merged file.
///
/// Keyed by section index alone: one section renders as exactly one card, so a
/// single number addresses the section, the card and the cue at once. The
/// catalogue's cue needs `(learningItemId, documentIndex)` because a keypoint is
/// assembled from authored learning items; a generated lesson is not.
@freezed
abstract class UserLessonAudioCueEntity with _$UserLessonAudioCueEntity {
  const factory UserLessonAudioCueEntity({
    @Default(0) int sectionIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _UserLessonAudioCueEntity;
}

@freezed
abstract class UserLessonAudioEntity with _$UserLessonAudioEntity {
  const factory UserLessonAudioEntity({
    @Default('') String url,
    @Default(0) int durationMs,
    @Default(<UserLessonAudioCueEntity>[]) List<UserLessonAudioCueEntity> cues,
  }) = _UserLessonAudioEntity;
}

extension UserLessonAudioEntityX on UserLessonAudioEntity {
  bool get isPlayable => url.isNotEmpty && cues.isNotEmpty;

  /// Which card the voice is currently reading.
  ///
  /// Returns the LAST cue that has started, not the one whose range contains the
  /// position: a silent section has a zero-length cue, and a containment test
  /// would never match it, leaving the deck stuck on the previous card while the
  /// voice moved on.
  int cardAt(Duration position) {
    final ms = position.inMilliseconds;
    var index = 0;
    for (final cue in cues) {
      if (cue.startMs <= ms) {
        index = cue.sectionIndex;
      } else {
        break;
      }
    }

    return index;
  }

  Duration startOfCard(int sectionIndex) {
    for (final cue in cues) {
      if (cue.sectionIndex == sectionIndex) {
        return Duration(milliseconds: cue.startMs);
      }
    }

    return Duration.zero;
  }
}

/// A lesson the user generated from their own material.
///
/// The list screen gets these WITHOUT [sections] (the API leaves the body out of
/// the list response — a page of ten lessons would otherwise ship ~50k words to
/// draw ten cards), so treat an empty `sections` on a card as "not loaded yet",
/// not as "empty lesson".
@freezed
abstract class UserLessonEntity with _$UserLessonEntity {
  const factory UserLessonEntity({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String outputLocale,
    @Default(ImportSourceTypeEntity.unknown) ImportSourceTypeEntity sourceType,

    /// Filename or video title, shown under the title on the card.
    @Default('') String sourceLabel,
    @Default(0) int wordCount,
    @Default(0) int estimatedMinutes,

    /// How far the reader got, as a section index.
    ///
    /// Still a section index even though the reader is one continuous scroll:
    /// the app reports the topmost visible section when it leaves, and restoring
    /// to a section boundary survives a re-render or a font-size change, which a
    /// raw scroll offset would not.
    @Default(0) int stopAtSectionIndex,
    DateTime? createdAt,
    @Default(<LessonSectionEntity>[]) List<LessonSectionEntity> sections,

    /// Narration state. Present on both the list card and the detail, so the
    /// card can draw a headphone badge without fetching the body.
    @Default(UserLessonAudioStatusEntity.none)
    UserLessonAudioStatusEntity audioStatus,

    /// The merged narration. Detail only — the list endpoint never sends it.
    UserLessonAudioEntity? audio,
  }) = _UserLessonEntity;
}

extension UserLessonEntityX on UserLessonEntity {
  bool get hasBody => sections.isNotEmpty;

  /// Whether the headphone control should appear at all.
  bool get canListen =>
      audioStatus == UserLessonAudioStatusEntity.ready &&
      (audio?.isPlayable ?? false);

  /// Narration is still being made. The card shows a quiet "đang tạo tiếng"
  /// hint rather than a control that would do nothing.
  bool get isDubbing => audioStatus == UserLessonAudioStatusEntity.processing;

  /// Reading progress as a 0-100 int, for the card's label.
  ///
  /// Section-granular by nature, so a lesson opened but not finished reads as
  /// e.g. "20% read" rather than anything finer. Good enough to answer "did I
  /// start this?", which is all the card is asking.
  int get readPercent {
    if (sections.isEmpty || stopAtSectionIndex <= 0) return 0;

    return ((stopAtSectionIndex / sections.length) * 100).clamp(0, 100).round();
  }
}
