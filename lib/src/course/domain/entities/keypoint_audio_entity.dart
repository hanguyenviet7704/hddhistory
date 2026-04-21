part of '../../course.dart';

@freezed
abstract class KeypointAudioEntity with _$KeypointAudioEntity {
  const factory KeypointAudioEntity({
    BaseMultiLanguage? url,
    BaseMultiLanguage? text,
  }) = _KeypointAudioEntity;

  factory KeypointAudioEntity.fromJson(Map<String, dynamic> json) => _$KeypointAudioEntityFromJson(json);
}
