part of '../../onboard.dart';

@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,
    @Default([]) List<OnboardOptionEntity> age,
    @Default([]) List<OnboardOptionEntity> gender,
    @Default([]) List<OnboardOptionEntity> skillsetWantToMaster,
    @Default([]) List<OnboardOptionEntity> learningGoal,
    @Default([]) List<OnboardOptionEntity> learningStruggles,
    @Default([]) List<OnboardOptionEntity> comfortableLearningTime,
    @Default([]) List<OnboardOptionEntity> dailyLearningGoal,
    @Default([]) List<OnboardIntroEntity> intro,
    @Default([]) List<OnboardMotivationEntity> welcome,
    @Default([]) List<OnboardMotivationEntity> motivationOne,
    @Default([]) List<OnboardMotivationEntity> motivationTwo,
    @Default([]) List<OnboardMotivationEntity> motivationThree,
    @Default([]) List<OnboardMotivationEntity> loading,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
