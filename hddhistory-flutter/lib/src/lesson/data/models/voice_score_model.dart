part of '../../lesson.dart';

@freezed
abstract class VoiceScoreModel with _$VoiceScoreModel {
  const factory VoiceScoreModel({
    @Default(0.0) double score,
    @Default(0.0) double timeGpt,
  }) = _VoiceScoreModel;

  factory VoiceScoreModel.fromJson(Map<String, dynamic> json) => _$VoiceScoreModelFromJson(json);
}

extension VoiceScoreModelExtension on VoiceScoreModel {
  VoiceScoreEntity toEntity() => VoiceScoreEntity(
    score: score,
    timeGpt: timeGpt,
  );
}
