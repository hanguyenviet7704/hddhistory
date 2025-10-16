part of '../../onboard.dart';

@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    @Default('') String dailyLearningGoal,
    @Default('') String timeToBecomeSkilled,
    @Default([]) List<OnboardOptionEntity> topicsWantToMaster,
    @Default([]) List<OnboardOptionEntity> seemLikeYou,
    @Default([]) List<OnboardOptionEntity> strugglesWhenSpeaking,
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
