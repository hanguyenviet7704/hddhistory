part of '../../course.dart';

@freezed
abstract class KeypointAudioModel with _$KeypointAudioModel {
  const factory KeypointAudioModel({
    BaseMultiLanguage? url,
    BaseMultiLanguage? text,

    /// Per-card clips keyed by language — see [KeypointAudioEntity.segments].
    Map<String, List<String>>? segments,
  }) = _KeypointAudioModel;

  factory KeypointAudioModel.fromJson(Map<String, dynamic> json) => _$KeypointAudioModelFromJson(json);
}

extension KeypointAudioModelExtension on KeypointAudioModel {
  KeypointAudioEntity toEntity() => KeypointAudioEntity(
    url: url,
    text: text,
    segments: segments,
  );
}
