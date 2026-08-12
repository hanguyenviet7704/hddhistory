part of '../../learning_import.dart';

@freezed
abstract class LessonBlockModel with _$LessonBlockModel {
  const factory LessonBlockModel({
    // An unrecognised block kind reads as a paragraph rather than throwing: the
    // text is still worth showing, and losing the whole lesson over one block we
    // do not know how to style yet would be a bad trade.
    @JsonKey(unknownEnumValue: LessonBlockTypeEntity.paragraph)
    @Default(LessonBlockTypeEntity.paragraph)
    LessonBlockTypeEntity type,
    @Default('') String text,
  }) = _LessonBlockModel;

  factory LessonBlockModel.fromJson(Map<String, dynamic> json) =>
      _$LessonBlockModelFromJson(json);
}

@freezed
abstract class LessonSectionModel with _$LessonSectionModel {
  const factory LessonSectionModel({
    @Default('') String title,
    @Default(<LessonBlockModel>[]) List<LessonBlockModel> blocks,
  }) = _LessonSectionModel;

  factory LessonSectionModel.fromJson(Map<String, dynamic> json) =>
      _$LessonSectionModelFromJson(json);
}

@freezed
abstract class LessonKeypointModel with _$LessonKeypointModel {
  const factory LessonKeypointModel({
    @Default('') String title,
    @Default('') String takeaway,
    @Default(<LessonSectionModel>[]) List<LessonSectionModel> sections,
  }) = _LessonKeypointModel;

  factory LessonKeypointModel.fromJson(Map<String, dynamic> json) =>
      _$LessonKeypointModelFromJson(json);
}

@freezed
abstract class UserLessonAudioCueModel with _$UserLessonAudioCueModel {
  const factory UserLessonAudioCueModel({
    int? cardIndex,

    /// What `cardIndex` was called before the keypoint split, when a lesson was
    /// one flat card list. Nullable so "absent" is distinguishable from zero —
    /// with defaults, an old cue would silently read as card 0.
    int? sectionIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _UserLessonAudioCueModel;

  factory UserLessonAudioCueModel.fromJson(Map<String, dynamic> json) =>
      _$UserLessonAudioCueModelFromJson(json);
}

@freezed
abstract class UserLessonKeypointAudioModel
    with _$UserLessonKeypointAudioModel {
  const factory UserLessonKeypointAudioModel({
    @Default(0) int keypointIndex,
    @Default('') String url,
    @Default(0) int durationMs,
    @Default(<UserLessonAudioCueModel>[]) List<UserLessonAudioCueModel> cues,
  }) = _UserLessonKeypointAudioModel;

  factory UserLessonKeypointAudioModel.fromJson(Map<String, dynamic> json) =>
      _$UserLessonKeypointAudioModelFromJson(json);
}

@freezed
abstract class UserLessonAudioModel with _$UserLessonAudioModel {
  const factory UserLessonAudioModel({
    @Default(<UserLessonKeypointAudioModel>[])
    List<UserLessonKeypointAudioModel> keypoints,

    // Pre-split narration: ONE file for the whole lesson. Read only so a lesson
    // dubbed before the change keeps its voice — see [UserLessonAudioModelX].
    @Default('') String url,
    @Default(0) int durationMs,
    @Default(<UserLessonAudioCueModel>[]) List<UserLessonAudioCueModel> cues,
  }) = _UserLessonAudioModel;

  factory UserLessonAudioModel.fromJson(Map<String, dynamic> json) =>
      _$UserLessonAudioModelFromJson(json);
}

@freezed
abstract class UserLessonModel with _$UserLessonModel {
  const factory UserLessonModel({
    @Default('') String id,
    @Default('') String title,
    @Default('') String description,
    @Default('') String outputLocale,
    @JsonKey(unknownEnumValue: ImportSourceTypeEntity.unknown)
    @Default(ImportSourceTypeEntity.unknown)
    ImportSourceTypeEntity sourceType,
    @Default('') String sourceLabel,
    @Default(0) int wordCount,
    @Default(0) int estimatedMinutes,
    @Default(0) int stopAtKeypointIndex,
    @Default(0) int stopAtSectionIndex,
    String? completedAt,
    String? additionalContentRequestedAt,
    String? createdAt,
    // Absent on the list endpoint by design (the API leaves the body out of the
    // card payload), so this defaults to empty rather than being nullable.
    @Default(<LessonKeypointModel>[]) List<LessonKeypointModel> keypoints,

    /// The pre-split body: one flat card list, no keypoints.
    ///
    /// Read only, and it is the app's OWN back-compat rather than a duplicate of
    /// the server's. The two are needed independently: a new app ships before
    /// the API it talks to more often than not, and without this the reader
    /// simply refuses every lesson until the backend catches up.
    @Default(<LessonSectionModel>[]) List<LessonSectionModel> sections,
    // A status the server adds later must degrade to `none`, not throw and take
    // the whole list response down with it.
    @JsonKey(unknownEnumValue: UserLessonAudioStatusEntity.none)
    @Default(UserLessonAudioStatusEntity.none)
    UserLessonAudioStatusEntity audioStatus,
    UserLessonAudioModel? audio,
  }) = _UserLessonModel;

  factory UserLessonModel.fromJson(Map<String, dynamic> json) =>
      _$UserLessonModelFromJson(json);
}

extension LessonBlockModelX on LessonBlockModel {
  LessonBlockEntity toEntity() => LessonBlockEntity(type: type, text: text);
}

extension LessonSectionModelX on LessonSectionModel {
  LessonSectionEntity toEntity() => LessonSectionEntity(
    title: title,
    blocks: blocks.map((block) => block.toEntity()).toList(),
  );
}

extension LessonKeypointModelX on LessonKeypointModel {
  LessonKeypointEntity toEntity() => LessonKeypointEntity(
    title: title,
    takeaway: takeaway,
    sections: sections.map((section) => section.toEntity()).toList(),
  );
}

extension UserLessonAudioCueModelX on UserLessonAudioCueModel {
  UserLessonAudioCueEntity toEntity() => UserLessonAudioCueEntity(
    cardIndex: cardIndex ?? sectionIndex ?? 0,
    startMs: startMs,
    durMs: durMs,
  );
}

extension UserLessonKeypointAudioModelX on UserLessonKeypointAudioModel {
  UserLessonKeypointAudioEntity toEntity() => UserLessonKeypointAudioEntity(
    keypointIndex: keypointIndex,
    url: url,
    durationMs: durationMs,
    cues: cues.map((cue) => cue.toEntity()).toList(),
  );
}

extension UserLessonAudioModelX on UserLessonAudioModel {
  /// Narration, from either era.
  ///
  /// A pre-split lesson has one file for the whole lesson and cues numbered
  /// across it — which is EXACTLY what a single keypoint looks like, because
  /// that is what [UserLessonModelX.toEntity] folds such a lesson into. So the
  /// old shape converts without losing anything: same file, same cue order, now
  /// addressed as keypoint 0.
  UserLessonAudioEntity toEntity() {
    if (keypoints.isNotEmpty) {
      return UserLessonAudioEntity(
        keypoints: keypoints.map((keypoint) => keypoint.toEntity()).toList(),
      );
    }
    if (url.isEmpty) return const UserLessonAudioEntity();

    return UserLessonAudioEntity(
      keypoints: [
        UserLessonKeypointAudioEntity(
          keypointIndex: 0,
          url: url,
          durationMs: durationMs,
          cues: cues.map((cue) => cue.toEntity()).toList(),
        ),
      ],
    );
  }
}

extension UserLessonModelX on UserLessonModel {
  UserLessonEntity toEntity() => UserLessonEntity(
    id: id,
    title: title,
    description: description,
    outputLocale: outputLocale,
    sourceType: sourceType,
    sourceLabel: sourceLabel,
    wordCount: wordCount,
    estimatedMinutes: estimatedMinutes,
    stopAtKeypointIndex: stopAtKeypointIndex,
    stopAtSectionIndex: stopAtSectionIndex,
    completedAt: DateTime.tryParse(completedAt ?? ''),
    additionalContentRequestedAt: DateTime.tryParse(
      additionalContentRequestedAt ?? '',
    ),
    createdAt: DateTime.tryParse(createdAt ?? ''),
    keypoints: _resolvedKeypoints,
    audioStatus: audioStatus,
    audio: audio?.toEntity(),
  );

  /// The body, whichever era the server is from.
  ///
  /// A pre-split lesson becomes ONE keypoint holding all its cards. That is the
  /// honest reading of it — the lesson was authored as a single sitting — and it
  /// keeps the reader's narration cues aligned, since a lesson-wide cue index
  /// and a single keypoint's card index are the same number.
  List<LessonKeypointEntity> get _resolvedKeypoints {
    if (keypoints.isNotEmpty) {
      return keypoints.map((keypoint) => keypoint.toEntity()).toList();
    }
    if (sections.isEmpty) return const [];

    return [
      LessonKeypointEntity(
        title: title,
        sections: sections.map((section) => section.toEntity()).toList(),
      ),
    ];
  }
}
