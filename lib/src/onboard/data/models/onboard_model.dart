part of '../../onboard.dart';

@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    String id,
    List<OnboardOptionModel> age,
    List<OnboardOptionModel> gender,
    List<OnboardOptionModel> topicsWantToMaster,
    List<OnboardOptionModel> seemLikeYou,
    List<OnboardOptionModel> strugglesWhenSpeaking,
    List<OnboardOptionModel> comfortableLearningTime,
    List<OnboardOptionModel> dailyLearningGoal,
    List<OnboardOptionModel> timeToBecomeSkilled,
    DateTime createdAt,
    DateTime updatedAt,
  }) = _OnboardModel;

  factory OnboardModel.fromJson(Map<String, dynamic> json) => _$OnboardModelFromJson(json);
}

extension OnboardModelExtension on OnboardModel {
  OnboardEntity toEntity() => OnboardEntity(
    id: id,
    isNativeEnglishSpeaker: isNativeEnglishSpeaker,
    comfortableLearningTime: comfortableLearningTime,
    dailyLearningGoal: dailyLearningGoal,
    timeToBecomeSkilled: timeToBecomeSkilled,
    topicsWantToMaster: topicsWantToMaster.map((model) => model.toEntity()).toList(),
    seemLikeYou: seemLikeYou.map((model) => model.toEntity()).toList(),
    strugglesWhenSpeaking: strugglesWhenSpeaking.map((model) => model.toEntity()).toList(),
  );
}
