part of '../../data_collect.dart';

@freezed
abstract class DataCollectState with _$DataCollectState {
  const factory DataCollectState({
    @Default(DataCollectStatus.initial) DataCollectStatus status,
    @Default([]) List<UserCollectDataEntity> items,
    UserCollectDataEntity? selectedItem,
    String? errorMessage,
    String? selectedAgeRange,
    String? selectedGender,
    String? userName,
    bool? isNativeEnglishSpeaker,
    @Default([]) List<String> selectedTopics,
    @Default([]) List<bool> selectedThisDescribeYouOptions,
    @Default([]) List<String> selectedStruggles,
    String? selectedBestTimeToLearn,
    String? selectedDailyLearningGoal,
    String? selectedTimeToBecomeSkilled,
    @Default(DataCollectStep.name) DataCollectStep currentStep,
    // Analysis progress fields
    @Default(0.0) double personalBackgroundProgress,
    @Default(0.0) double difficultiesProgress,
    @Default(0.0) double learningGoalProgress,
    @Default(0.0) double studyHabitsProgress,
    @Default(false) bool analysisComplete,
  }) = _DataCollectState;

  factory DataCollectState.initial() => const DataCollectState();

  factory DataCollectState.fromJson(Map<String, dynamic> json) => _$DataCollectStateFromJson(json);
}

enum DataCollectStatus { initial, loading, success, failure }

enum DataCollectStep {
  name,
  age,
  gender,
  englishIsYourNativeLanguage,
  chooseTopic,
  doesThisDescribeYou,
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
    DataCollectStep.englishIsYourNativeLanguage => isNativeEnglishSpeaker != null,
    DataCollectStep.chooseTopic => selectedTopics.isNotEmpty,
    DataCollectStep.doesThisDescribeYou => selectedThisDescribeYouOptions.isNotEmpty,
    DataCollectStep.whatDoYouUsuallyStruggleWithWhenSpeaking => selectedStruggles.isNotEmpty,
    DataCollectStep.bestTimeOfDayToLearn => selectedBestTimeToLearn != null,
    DataCollectStep.dailyLearningGoal => selectedDailyLearningGoal != null,
    DataCollectStep.howMuchTimeYouWantToBecomeSkilled => selectedTimeToBecomeSkilled != null,
  };
}
