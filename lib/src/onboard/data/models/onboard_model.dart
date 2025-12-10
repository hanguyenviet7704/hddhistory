part of '../../onboard.dart';

@freezed
abstract class OnboardModel with _$OnboardModel {
  const factory OnboardModel({
    @Default(0) int id,
    @Default([]) List<OnboardIntroModel> intro,
    @Default([]) List<OnboardOptionModel> age,
    @Default([]) List<OnboardOptionModel> gender,
    @Default([]) List<OnboardOptionModel> skillsetWantToMaster,
    @Default([]) List<OnboardOptionModel> learningGoal,
    @Default([]) List<OnboardOptionModel> learningStruggles,
    @Default([]) List<OnboardOptionModel> comfortableLearningTime,
    @Default([]) List<OnboardOptionModel> dailyLearningGoal,
    @Default([]) List<OnboardMotivationModel> welcome,
    @Default([]) List<OnboardMotivationModel> motivationOne,
    @Default([]) List<OnboardMotivationModel> motivationTwo,
    @Default([]) List<OnboardMotivationModel> motivationThree,
    @Default([]) List<OnboardMotivationModel> loading,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _OnboardModel;

  factory OnboardModel.fromJson(Map<String, dynamic> json) => _$OnboardModelFromJson(json);
}

extension OnboardModelExtension on OnboardModel {
  OnboardEntity toEntity() => OnboardEntity(
    id: id.toString(),
    age: age.map((model) => model.toEntity()).toList(),
    gender: gender.map((model) => model.toEntity()).toList(),
    skillsetWantToMaster: skillsetWantToMaster.map((model) => model.toEntity()).toList(),
    learningGoal: learningGoal.map((model) => model.toEntity()).toList(),
    learningStruggles: learningStruggles.map((model) => model.toEntity()).toList(),
    comfortableLearningTime: comfortableLearningTime.map((model) => model.toEntity()).toList(),
    dailyLearningGoal: dailyLearningGoal.map((model) => model.toEntity()).toList(),
    intro: intro.map((model) => model.toEntity()).toList(),
    welcome: welcome.map((model) => model.toEntity()).toList(),
    motivationOne: motivationOne.map((model) => model.toEntity()).toList(),
    motivationTwo: motivationTwo.map((model) => model.toEntity()).toList(),
    motivationThree: motivationThree.map((model) => model.toEntity()).toList(),
    loading: loading.map((model) => model.toEntity()).toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
