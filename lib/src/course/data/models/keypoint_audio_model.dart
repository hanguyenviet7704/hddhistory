part of '../../course.dart';

@freezed
abstract class KeypointAudioModel with _$KeypointAudioModel {
  const factory KeypointAudioModel({
    BaseMultiLanguage? url,
    BaseMultiLanguage? text,

    /// Per-card clips keyed by language — see [KeypointAudioEntity.segments].
    Map<String, List<String>>? segments,

    /// One merged theory-narration file per language — see
    /// [KeypointAudioEntity.merged].
    Map<String, MergedKeypointAudioModel>? merged,
  }) = _KeypointAudioModel;

  factory KeypointAudioModel.fromJson(Map<String, dynamic> json) => _$KeypointAudioModelFromJson(json);
}

@freezed
abstract class MergedAudioCueModel with _$MergedAudioCueModel {
  const factory MergedAudioCueModel({
    @Default('') String learningItemId,
    @Default(0) int documentIndex,
    @Default(0) int startMs,
    @Default(0) int durMs,
  }) = _MergedAudioCueModel;

  factory MergedAudioCueModel.fromJson(Map<String, dynamic> json) => _$MergedAudioCueModelFromJson(json);
}

@freezed
abstract class MergedKeypointAudioModel with _$MergedKeypointAudioModel {
  const factory MergedKeypointAudioModel({
    @Default('') String url,
    @Default(0) int durationMs,
    @Default([]) List<MergedAudioCueModel> cues,
  }) = _MergedKeypointAudioModel;

  factory MergedKeypointAudioModel.fromJson(Map<String, dynamic> json) => _$MergedKeypointAudioModelFromJson(json);
}

extension KeypointAudioModelExtension on KeypointAudioModel {
  KeypointAudioEntity toEntity() => KeypointAudioEntity(
    url: url,
    text: text,
    segments: segments,
    merged: merged?.map((lang, model) => MapEntry(lang, model.toEntity())),
  );
}

extension MergedAudioCueModelExtension on MergedAudioCueModel {
  MergedAudioCueEntity toEntity() => MergedAudioCueEntity(
    learningItemId: learningItemId,
    documentIndex: documentIndex,
    startMs: startMs,
    durMs: durMs,
  );
}

extension MergedKeypointAudioModelExtension on MergedKeypointAudioModel {
  MergedKeypointAudioEntity toEntity() => MergedKeypointAudioEntity(
    url: url,
    durationMs: durationMs,
    cues: cues.map((cue) => cue.toEntity()).toList(),
  );
}
