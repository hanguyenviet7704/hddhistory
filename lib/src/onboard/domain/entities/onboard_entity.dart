part of '../../onboard.dart';

@freezed
abstract class OnboardEntity with _$OnboardEntity {
  const factory OnboardEntity({
    @Default('') String id,
    @Default([]) List<OnboardOptionEntity> age,
    @Default([]) List<OnboardOptionEntity> gender,
    @Default([]) List<OnboardOptionEntity> categoryWantToMaster,
    @Default([]) List<OnboardOptionEntity> learningGoal,
    @Default([]) List<OnboardOptionEntity> learningStruggles,
    @Default([]) List<OnboardOptionEntity> comfortableLearningTime,
    @Default([]) List<OnboardOptionEntity> dailyLearningGoal,
    @Default([]) List<OnboardPathEntity> paths,
    @Default([]) List<OnboardCopyEntity> copy,
    @Default([]) List<OnboardIntroEntity> intro,
    @Default(OnboardMotivationEntity()) OnboardMotivationEntity welcome,
    @Default(OnboardMotivationEntity()) OnboardMotivationEntity motivationOne,
    @Default(OnboardMotivationEntity()) OnboardMotivationEntity motivationTwo,
    @Default(OnboardMotivationEntity()) OnboardMotivationEntity motivationThree,
    @Default(OnboardMotivationEntity()) OnboardMotivationEntity loading,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardEntity;

  factory OnboardEntity.fromJson(Map<String, dynamic> json) => _$OnboardEntityFromJson(json);
}
