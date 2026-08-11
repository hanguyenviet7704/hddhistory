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
abstract class UserLessonAudioCueModel with _$UserLessonAudioCueModel {
  const factory UserLessonAudioCueModel({
    @Default(0) int sectionIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _UserLessonAudioCueModel;

  factory UserLessonAudioCueModel.fromJson(Map<String, dynamic> json) =>
      _$UserLessonAudioCueModelFromJson(json);
}

@freezed
abstract class UserLessonAudioModel with _$UserLessonAudioModel {
  const factory UserLessonAudioModel({
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
    @Default(0) int stopAtSectionIndex,
    String? createdAt,
    // Absent on the list endpoint by design (the API leaves the body out of the
    // card payload), so this defaults to empty rather than being nullable.
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

extension UserLessonAudioCueModelX on UserLessonAudioCueModel {
  UserLessonAudioCueEntity toEntity() => UserLessonAudioCueEntity(
    sectionIndex: sectionIndex,
    startMs: startMs,
    durMs: durMs,
  );
}

extension UserLessonAudioModelX on UserLessonAudioModel {
  UserLessonAudioEntity toEntity() => UserLessonAudioEntity(
    url: url,
    durationMs: durationMs,
    cues: cues.map((cue) => cue.toEntity()).toList(),
  );
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
    stopAtSectionIndex: stopAtSectionIndex,
    createdAt: DateTime.tryParse(createdAt ?? ''),
    sections: sections.map((section) => section.toEntity()).toList(),
    audioStatus: audioStatus,
    audio: audio?.toEntity(),
  );
}
