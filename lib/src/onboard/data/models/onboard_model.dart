part of '../../onboard.dart';

@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    @Default('') String id,
    @Default([]) List<OnboardOptionModel> age,
    @Default([]) List<OnboardOptionModel> gender,
    @Default([]) List<OnboardOptionModel> topicsWantToMaster,
    @Default([]) List<OnboardOptionModel> seemLikeYou,
    @Default([]) List<OnboardOptionModel> strugglesWhenSpeaking,
    @Default([]) List<OnboardOptionModel> comfortableLearningTime,
    @Default([]) List<OnboardOptionModel> dailyLearningGoal,
    @Default([]) List<OnboardOptionModel> timeToBecomeSkilled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardModel;

  factory OnboardModel.fromJson(Map<String, dynamic> json) => _$OnboardModelFromJson(json);
}

extension OnboardModelExtension on OnboardModel {
  OnboardEntity toEntity() => OnboardEntity(
    id: id,
    age: age.map((model) => model.toEntity()).toList(),
    gender: gender.map((model) => model.toEntity()).toList(),
    topicsWantToMaster: topicsWantToMaster.map((model) => model.toEntity()).toList(),
    seemLikeYou: seemLikeYou.map((model) => model.toEntity()).toList(),
    strugglesWhenSpeaking: strugglesWhenSpeaking.map((model) => model.toEntity()).toList(),
    comfortableLearningTime: comfortableLearningTime.map((model) => model.toEntity()).toList(),
    dailyLearningGoal: dailyLearningGoal.map((model) => model.toEntity()).toList(),
    timeToBecomeSkilled: timeToBecomeSkilled.map((model) => model.toEntity()).toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
