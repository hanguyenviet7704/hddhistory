part of '../../onboard.dart';

@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    @Default('') String id,
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    @Default('') String dailyLearningGoal,
    @Default('') String timeToBecomeSkilled,
    @Default([]) List<OnboardOptionModel> topicsWantToMaster,
    @Default([]) List<OnboardOptionModel> seemLikeYou,
    @Default([]) List<OnboardOptionModel> strugglesWhenSpeaking,
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
