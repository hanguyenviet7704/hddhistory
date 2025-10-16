part of '../../onboard.dart';

@freezed
abstract class OnboardOptionModel with _$OnboardOptionModel {
  const factory OnboardOptionModel({
    @Default(false) bool isNativeEnglishSpeaker,
    @Default('') String comfortableLearningTime,
    @Default('') String dailyLearningGoal,
    @Default('') String timeToBecomeSkilled,
  }) = _OnboardOptionModel;

  factory OnboardOptionModel.fromJson(Map<String, dynamic> json) => _$OnboardOptionModelFromJson(json);
}

extension OnboardOptionModelExtension on OnboardOptionModel {
  OnboardOptionEntity toEntity() => OnboardOptionEntity(
    isNativeEnglishSpeaker: isNativeEnglishSpeaker,
    comfortableLearningTime: comfortableLearningTime,
    dailyLearningGoal: dailyLearningGoal,
    timeToBecomeSkilled: timeToBecomeSkilled,
  );
}
