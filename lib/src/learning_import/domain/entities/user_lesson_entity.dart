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

/// One card in the reader.
@freezed
abstract class LessonSectionEntity with _$LessonSectionEntity {
  const factory LessonSectionEntity({
    @Default('') String title,
    @Default(<LessonBlockEntity>[]) List<LessonBlockEntity> blocks,
  }) = _LessonSectionEntity;
}

/// A group of cards read as one sitting — the same unit a catalogue keypoint is.
///
/// This is what lets an imported lesson enter the catalogue's own reader rather
/// than a parallel one: [UserLessonCourseMapper] turns each of these into a
/// [KeypointEntity], so `LessonPage` cannot tell the two apart.
@freezed
abstract class LessonKeypointEntity with _$LessonKeypointEntity {
  const factory LessonKeypointEntity({
    @Default('') String title,

    /// Node thumbnail dealt server-side from the admin's keypoint-image pool.
    /// Empty (old lessons, empty pool) falls back to the bundled mock art.
    @Default('') String coverUrl,

    /// What the reader should leave this keypoint with — the BACK FACE of the
    /// recap card that ends it.
    ///
    /// A catalogue keypoint gets this from an authored "Take This With You"
    /// theory item, which a generated lesson has none of; `KeypointDoneCard`
    /// then falls back to `KeypointEntity.description`, which the mapper used to
    /// leave empty. The result was a recap card with nothing behind it, so it
    /// did not flip at all. Generated per keypoint by the model now.
    @Default('') String takeaway,
    @Default(<LessonSectionEntity>[]) List<LessonSectionEntity> sections,
  }) = _LessonKeypointEntity;
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

/// Whether the lesson BODY is all there yet.
///
/// Generation is two-phase since the progressive pipeline: the import job
/// completes once the FIRST keypoint is readable and listenable, and the rest
/// of the outline is written server-side behind the reader's back. [partial] is
/// that window — the roadmap keeps refetching while it sees it, and draws the
/// not-yet-written keypoints as "đang tạo" nodes from [UserLessonEntity.plannedKeypointTitles].
///
/// Lessons that predate the pipeline arrive as [complete].
enum UserLessonContentStatusEntity {
  @JsonValue('partial')
  partial,
  @JsonValue('complete')
  complete,
}

/// Where one card's narration sits inside its KEYPOINT's file.
///
/// `cardIndex` is relative to the keypoint, because the file it indexes into is
/// per keypoint. The catalogue's cue instead carries
/// `(learningItemId, documentIndex)`, since a catalogue keypoint is assembled
/// from authored learning items; [UserLessonCourseMapper] synthesises that pair
/// from this one when it builds the reader's entities.
@freezed
abstract class UserLessonAudioCueEntity with _$UserLessonAudioCueEntity {
  const factory UserLessonAudioCueEntity({
    @Default(0) int cardIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _UserLessonAudioCueEntity;
}

/// One keypoint's narration: its own file, its own cue map.
@freezed
abstract class UserLessonKeypointAudioEntity
    with _$UserLessonKeypointAudioEntity {
  const factory UserLessonKeypointAudioEntity({
    @Default(0) int keypointIndex,
    @Default('') String url,
    @Default(0) int durationMs,
    @Default(<UserLessonAudioCueEntity>[]) List<UserLessonAudioCueEntity> cues,
  }) = _UserLessonKeypointAudioEntity;
}

@freezed
abstract class UserLessonAudioEntity with _$UserLessonAudioEntity {
  const factory UserLessonAudioEntity({
    @Default(<UserLessonKeypointAudioEntity>[])
    List<UserLessonKeypointAudioEntity> keypoints,
  }) = _UserLessonAudioEntity;
}

extension UserLessonAudioEntityX on UserLessonAudioEntity {
  bool get isPlayable =>
      keypoints.any((keypoint) => keypoint.url.isNotEmpty && keypoint.cues.isNotEmpty);

  /// Narration for one keypoint, or null when that keypoint was never dubbed —
  /// a keypoint whose every card was silent produces no file at all.
  UserLessonKeypointAudioEntity? forKeypoint(int index) {
    for (final keypoint in keypoints) {
      if (keypoint.keypointIndex == index) return keypoint;
    }

    return null;
  }
}

/// A lesson the user generated from their own material.
///
/// The list screen gets these WITHOUT [keypoints] (the API leaves the body out
/// of the list response — a page of ten lessons would otherwise ship ~50k words
/// to draw ten cards), so treat empty `keypoints` on a card as "not loaded yet",
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

    /// The lesson's cover, dealt server-side from the admin pool at creation.
    /// Empty (old lessons, empty pool) falls back to the bundled mock art.
    @Default('') String coverUrl,
    @Default(0) int wordCount,
    @Default(0) int estimatedMinutes,

    /// Which keypoint the reader was last in — where opening the lesson resumes,
    /// the same way tapping a course lesson does.
    @Default(0) int stopAtKeypointIndex,

    /// How far into that keypoint, as a card index RELATIVE to it. A card
    /// boundary rather than a scroll offset: it survives a re-render or a
    /// font-size change, which a raw offset would not.
    @Default(0) int stopAtSectionIndex,

    /// When the reader reached the last card of the last keypoint, or null.
    ///
    /// Server-derived: only it holds the body, and the list response omits the
    /// keypoints — so this is the ONLY thing on a list card that can say the
    /// lesson is finished. Without it the card was stuck at
    /// `stopAtKeypointIndex / keypointCount`, which for a four-keypoint lesson
    /// read 75% forever.
    DateTime? completedAt,

    /// When the reader asked for more content on this lesson, from the panel at
    /// the end of its roadmap. Null until they do — and it is the SERVER's copy,
    /// so the answer survives a reinstall and cannot be re-asked on a new device.
    DateTime? additionalContentRequestedAt,
    DateTime? createdAt,
    @Default(<LessonKeypointEntity>[]) List<LessonKeypointEntity> keypoints,

    /// Narration state. Present on both the list card and the detail, so the
    /// card can draw a headphone badge without fetching the body.
    @Default(UserLessonAudioStatusEntity.none)
    UserLessonAudioStatusEntity audioStatus,

    /// The merged narration. Detail only — the list endpoint never sends it.
    UserLessonAudioEntity? audio,

    /// Whether the body is all there yet. See [UserLessonContentStatusEntity].
    @Default(UserLessonContentStatusEntity.complete)
    UserLessonContentStatusEntity contentStatus,

    /// The committed outline, by keypoint title, first one included. Detail
    /// only. While [contentStatus] is partial this is LONGER than [keypoints] —
    /// the tail names the nodes still being written.
    @Default(<String>[]) List<String> plannedKeypointTitles,

    /// Node artwork for that same outline — index i is the picture keypoint i
    /// carries once written. Dealt server-side at the same moment as
    /// [plannedKeypointTitles] so a roadmap node shows its FINAL picture from
    /// the first frame instead of a stand-in that swaps when the keypoint
    /// lands. Empty on lessons generated before the server dealt these.
    @Default(<String>[]) List<String> plannedKeypointCoverUrls,
  }) = _UserLessonEntity;
}

extension UserLessonEntityX on UserLessonEntity {
  bool get hasBody => keypoints.isNotEmpty;

  /// Every card in the lesson, keypoint boundaries ignored. For counting and
  /// progress only — the reader always works a keypoint at a time.
  int get cardCount =>
      keypoints.fold(0, (total, keypoint) => total + keypoint.sections.length);

  /// Whether the headphone control should appear at all.
  bool get canListen =>
      audioStatus == UserLessonAudioStatusEntity.ready &&
      (audio?.isPlayable ?? false);

  /// Narration is still being made. The card shows a quiet "đang tạo tiếng"
  /// hint rather than a control that would do nothing.
  bool get isDubbing => audioStatus == UserLessonAudioStatusEntity.processing;

  /// Reading progress as a 0-100 int, for the card's label.
  ///
  /// Measured in KEYPOINTS, not cards, and read off the list response — which
  /// carries no body, so a card-level percentage is not available there anyway.
  /// Keypoint-granular is also the honest unit: a keypoint is what the reader
  /// finishes, so "1 of 4" is what they actually did.
  int get readPercent {
    if (isCompleted) return 100;
    if (keypointCount <= 0 || stopAtKeypointIndex <= 0) return 0;

    return ((stopAtKeypointIndex / keypointCount) * 100).clamp(0, 100).round();
  }

  /// Read to the end. See [completedAt].
  bool get isCompleted => completedAt != null;

  /// Whether the "want more of this?" panel has already been answered with yes.
  bool get hasRequestedMoreContent => additionalContentRequestedAt != null;

  /// How many keypoints this lesson has.
  ///
  /// Falls back to `stopAtKeypointIndex + 1` on the LIST card, where the body is
  /// absent: without it every card would report 0% forever. The detail response
  /// carries the real list and overrides this.
  int get keypointCount =>
      keypoints.isNotEmpty ? keypoints.length : stopAtKeypointIndex + 1;

  /// The background phase is still writing keypoints.
  bool get isContentPartial =>
      contentStatus == UserLessonContentStatusEntity.partial;

  /// How many nodes the roadmap draws: the committed plan, or the body when it
  /// is somehow longer (a plan is a promise; the body is the fact).
  int get plannedKeypointCount => plannedKeypointTitles.length > keypoints.length
      ? plannedKeypointTitles.length
      : keypoints.length;

  /// The title for roadmap node [index], written or merely planned.
  String plannedTitleAt(int index) {
    if (index < keypoints.length) return keypoints[index].title;
    if (index < plannedKeypointTitles.length) {
      return plannedKeypointTitles[index];
    }

    return '';
  }

  /// Whether keypoint [index] can be OPENED: its text exists, and — while the
  /// progressive pipeline is still mid-flight — the narration it owes has
  /// arrived.
  ///
  /// The audio gate applies ONLY while [contentStatus] is partial, because that
  /// is the only time "no audio yet" reliably means "audio is coming". A
  /// COMPLETE lesson with holes in its narration is the OLD pipeline's damage
  /// (dub died partway, nothing on that server will ever retry) — gating on it
  /// dressed permanently-silent keypoints up as "Đang tạo…" forever, spinner
  /// and all (reported 2026-08-13, pre-deploy api-dev). Those open as ordinary
  /// silent keypoints, which the reader has always handled. Same reasoning for
  /// `failed`/`none` within the partial window: nothing is coming, don't wait.
  bool keypointReady(int index) {
    if (index < 0 || index >= keypoints.length) return false;
    if (!isContentPartial) return true;

    switch (audioStatus) {
      case UserLessonAudioStatusEntity.failed:
      case UserLessonAudioStatusEntity.none:
        return true;
      case UserLessonAudioStatusEntity.processing:
      case UserLessonAudioStatusEntity.ready:
        final entry = audio?.forKeypoint(index);

        return entry != null && entry.url.isNotEmpty;
    }
  }

  /// Whether the roadmap still has anything to wait for. Drives the refetch
  /// loop — and therefore MUST go false the moment the body is complete, or a
  /// lesson with permanent narration holes polls the API forever.
  bool get isStillMaterializing => isContentPartial;
}
