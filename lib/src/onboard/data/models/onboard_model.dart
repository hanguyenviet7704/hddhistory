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
    @Default(OnboardMotivationModel()) OnboardMotivationModel welcome,
    @Default(OnboardMotivationModel()) OnboardMotivationModel motivationOne,
    @Default(OnboardMotivationModel()) OnboardMotivationModel motivationTwo,
    @Default(OnboardMotivationModel()) OnboardMotivationModel motivationThree,
    @Default(OnboardMotivationModel()) OnboardMotivationModel loading,
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
    welcome: welcome.toEntity(),
    motivationOne: motivationOne.toEntity(),
    motivationTwo: motivationTwo.toEntity(),
    motivationThree: motivationThree.toEntity(),
    loading: loading.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
