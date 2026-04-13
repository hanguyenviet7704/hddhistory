part of '../../course.dart';

@freezed
abstract class KeypointAudioModel with _$KeypointAudioModel {
  const factory KeypointAudioModel({
    BaseMultiLanguage? url,
    BaseMultiLanguage? text,
  }) = _KeypointAudioModel;

  factory KeypointAudioModel.fromJson(Map<String, dynamic> json) => _$KeypointAudioModelFromJson(json);
}

extension KeypointAudioModelExtension on KeypointAudioModel {
  KeypointAudioEntity toEntity() => KeypointAudioEntity(
    url: url,
    text: text,
  );
}
