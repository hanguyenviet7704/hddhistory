part of '../../data_collect.dart';

@freezed
abstract class DataCollectState with _$DataCollectState {
  const factory DataCollectState({
    @Default(DataCollectStatus.initial) DataCollectStatus status,
    @Default(DataCollectStep.collectName) DataCollectStep currentStep,
    String? errorMessage,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    String? userName,
    OnboardOptionEntity? selectedAgeRange,
    OnboardOptionEntity? selectedGender,
    OnboardOptionEntity? selectedLearningGoal,
    @Default([]) List<OnboardOptionEntity> selectedSkillsetsWantToMaster,
    @Default([]) List<OnboardOptionEntity> selectedLearningStruggles,
    OnboardOptionEntity? selectedDailyLearningGoal,
    OnboardOptionEntity? selectedComfortableLearningTime,
    @Default(false) bool analysisComplete,

    // Analysis progress fields
    @Default(0.0) double personalBackgroundProgress,
    @Default(0.0) double difficultiesProgress,
    @Default(0.0) double learningGoalProgress,
    @Default(0.0) double studyHabitsProgress,
  }) = _DataCollectState;

  factory DataCollectState.initial() => const DataCollectState();

  factory DataCollectState.fromJson(Map<String, dynamic> json) => _$DataCollectStateFromJson(json);
}

enum DataCollectStatus { initial, loading, success, failure }

enum DataCollectStep {
  collectName,
  collectAge,
  collectGender,
  collectLearningGoal,
  collectSkillsetsWantToMaster,
  collectLearningStrugger,
  motivateHowToLearn,
  collectDailyLearningGoal,
  collectComfortableLearningTime,
}

extension DataCollectStepExtension on DataCollectStep {
  int get index => DataCollectStep.values.indexOf(this);

  double get progress => index / DataCollectStep.values.length;
}

extension DataCollectStateExtension on DataCollectState {
  bool get canContinue => switch (currentStep) {
    DataCollectStep.collectName => userName != null && userName!.isNotEmpty,
    DataCollectStep.collectAge => selectedAgeRange != null,
    DataCollectStep.collectGender => selectedGender != null,
    DataCollectStep.collectLearningGoal => selectedLearningGoal != null,
    DataCollectStep.collectSkillsetsWantToMaster => selectedSkillsetsWantToMaster.isNotEmpty,
    DataCollectStep.collectLearningStrugger => selectedLearningStruggles.isNotEmpty,
    DataCollectStep.motivateHowToLearn => true,
    DataCollectStep.collectDailyLearningGoal => selectedDailyLearningGoal != null,
    DataCollectStep.collectComfortableLearningTime => selectedComfortableLearningTime != null,
  };

  bool get isLastStep => currentStep == DataCollectStep.collectComfortableLearningTime;

  bool isLearningGoalSelected(OnboardOptionEntity learningGoal) => selectedLearningGoal?.id == learningGoal.id;
  bool isLearningStruggleSelected(OnboardOptionEntity learningStruggle) => selectedLearningStruggles.contains(learningStruggle);
}
