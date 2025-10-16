part of '../../data_collect.dart';

@freezed
abstract class DataCollectState with _$DataCollectState {
  const factory DataCollectState({
    @Default(DataCollectStatus.initial) DataCollectStatus status,
    @Default([]) List<UserCollectDataEntity> items,
    UserCollectDataEntity? selectedItem,
    String? errorMessage,
    String? selectedAgeRange,
    @Default(DataCollectStep.name) DataCollectStep currentStep,
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
