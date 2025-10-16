part of '../../onboard.dart';

@freezed
abstract class OnboardOptionEntity with _$OnboardOptionEntity {
  const factory OnboardOptionEntity({
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    @Default('') String dailyLearningGoal,
    @Default('') String timeToBecomeSkilled,
  }) = _OnboardOptionEntity;

  factory OnboardOptionEntity.fromJson(Map<String, dynamic> json) => _$OnboardOptionEntityFromJson(json);
}
