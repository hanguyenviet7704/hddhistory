part of '../../lesson.dart';

@freezed
abstract class VoiceScoreEntity with _$VoiceScoreEntity {
  const factory VoiceScoreEntity({
    @Default(0.0) double score,
    @Default(0.0) double timeGpt,
  }) = _VoiceScoreEntity;

  factory VoiceScoreEntity.fromJson(Map<String, dynamic> json) => _$VoiceScoreEntityFromJson(json);
}
