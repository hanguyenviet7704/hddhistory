part of '../../data_collect.dart';

@freezed
abstract class DataCollectState with _$DataCollectState {
  const factory DataCollectState({
    @Default(DataCollectStatus.initial) DataCollectStatus status,
    @Default(DataCollectStep.name) DataCollectStep currentStep,
    String? errorMessage,
    @Default(OnboardEntity()) OnboardEntity onboardData,
    String? userName,
    OnboardOptionEntity? selectedAgeRange,
    OnboardOptionEntity? selectedGender,
    @Default([]) List<OnboardOptionEntity> selectedTopics,
    @Default([]) List<OnboardOptionEntity> selectedStruggles,
    OnboardOptionEntity? selectedBestTimeToLearn,
    OnboardOptionEntity? selectedDailyLearningGoal,
    OnboardOptionEntity? selectedTimeToBecomeSkilled,
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
  name,
  age,
  gender,
  chooseTopic,
  whatDoYouUsuallyStruggleWithWhenSpeaking,
  bestTimeOfDayToLearn,
  dailyLearningGoal,
  howMuchTimeYouWantToBecomeSkilled,
}

extension DataCollectStepExtension on DataCollectStep {
  int get index => DataCollectStep.values.indexOf(this);

  double get progress => index / DataCollectStep.values.length;
}

extension DataCollectStateExtension on DataCollectState {
  bool get canContinue => switch (currentStep) {
    DataCollectStep.name => userName != null && userName!.isNotEmpty,
    DataCollectStep.age => selectedAgeRange != null,
    DataCollectStep.gender => selectedGender != null,
    DataCollectStep.chooseTopic => selectedTopics.isNotEmpty,
    DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking => selectedStruggles.isNotEmpty,
    DataCollectStep.bestTimeOfDayToLearn => selectedBestTimeToLearn != null,
    DataCollectStep.dailyLearningGoal => selectedDailyLearningGoal != null,
    DataCollectStep.howMuchTimeYouWantToBecomeSkilled => selectedTimeToBecomeSkilled != null,
  };

  bool get isLastStep => currentStep == DataCollectStep.howMuchTimeYouWantToBecomeSkilled;

  bool isTopicSelected(OnboardOptionEntity topic) => selectedTopics.contains(topic);
  bool isStruggleSelected(OnboardOptionEntity struggle) => selectedStruggles.contains(struggle);
}
