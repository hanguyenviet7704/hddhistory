part of '../../onboard.dart';

@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,
    @Default([]) List<OnboardOptionEntity> age,
    @Default([]) List<OnboardOptionEntity> gender,
    @Default([]) List<OnboardOptionEntity> topicsWantToMaster,
    @Default([]) List<OnboardOptionEntity> seemLikeYou,
    @Default([]) List<OnboardOptionEntity> strugglesWhenSpeaking,
    @Default([]) List<OnboardOptionEntity> comfortableLearningTime,
    @Default([]) List<OnboardOptionEntity> dailyLearningGoal,
    @Default([]) List<OnboardOptionEntity> timeToBecomeSkilled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
