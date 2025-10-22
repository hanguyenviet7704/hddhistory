part of '../../data_collect.dart';

@lazySingleton
class DataCollectCubit extends Cubit<DataCollectState> with CubitUseCaseHandlerMixin<DataCollectState> {
  final DeviceInfoService _deviceInfoService;
  final LoginAnonymousUsecase _loginAnonymousUsecase;

  DataCollectCubit(this._loginAnonymousUsecase, this._deviceInfoService) : super(DataCollectState.initial());

  TextEditingController nameController = TextEditingController();

  void loginAnonymous() async {
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = AppDI.injector.get<LocaleCubit>().state.value;
    runUseCase(
      usecase: () => _loginAnonymousUsecase({
        "device": {
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
        "name": nameController.text,
        "languagge": languageCode,
        "age": state.selectedAgeRange?.label,
        "gender": state.selectedGender?.label,
        "onboarding": {
          "isNativeEnglishSpeaker": true,
          "comfortableLearningTime": state.selectedBestTimeToLearn?.label,
          "dailyLearningGoal": state.selectedDailyLearningGoal?.label,
          "timeToBecomeSkilled": state.selectedTimeToBecomeSkilled?.label,
          "skillsetWantToMaster": state.selectedTopics.map((e) => e.label).toList(),
          "seemLikeYou": state.selectedStruggles.map((e) => e.label).toList(),
          "strugglesWhenSpeaking": state.selectedStruggles.map((e) => e.label).toList(),
        },
      }),
      onSuccess: (data) {},
      onFailure: (error) {},
    );
  }

  void goToNextStep() {
    final allSteps = DataCollectStep.values;
    final currentIndex = allSteps.indexOf(state.currentStep);

    if (currentIndex < allSteps.length - 1) {
      emit(state.copyWith(currentStep: allSteps[currentIndex + 1]));
    }
  }

  void goToPreviousStep() {
    final allSteps = DataCollectStep.values;
    final currentIndex = allSteps.indexOf(state.currentStep);

    if (currentIndex > 0) {
      emit(state.copyWith(currentStep: allSteps[currentIndex - 1]));
    }
  }

  void goToStep(DataCollectStep step) {
    emit(state.copyWith(currentStep: step));
  }

  void updateUserName(String name) => emit(state.copyWith(userName: name));
  void setOnboardData(OnboardEntity onboardData) => emit(state.copyWith(onboardData: onboardData));
  void selectAgeRange(OnboardOptionEntity ageRange) => emit(state.copyWith(selectedAgeRange: ageRange));
  void selectGender(OnboardOptionEntity gender) => emit(state.copyWith(selectedGender: gender));
  void selectTopic(OnboardOptionEntity topic) {
    final topics = List<OnboardOptionEntity>.from(state.selectedTopics);
    if (topics.contains(topic)) {
      topics.remove(topic);
    } else {
      topics.add(topic);
    }
    emit(state.copyWith(selectedTopics: topics));
  }

  void selectStruggle(OnboardOptionEntity struggle) {
    final struggles = List<OnboardOptionEntity>.from(state.selectedStruggles);
    if (struggles.contains(struggle)) {
      struggles.remove(struggle);
    } else {
      struggles.add(struggle);
    }
    emit(state.copyWith(selectedStruggles: struggles));
  }

  void selectBestTimeToLearn(OnboardOptionEntity bestTimeToLearn) => emit(state.copyWith(selectedBestTimeToLearn: bestTimeToLearn));
  void selectDailyLearningGoal(OnboardOptionEntity dailyLearningGoal) => emit(state.copyWith(selectedDailyLearningGoal: dailyLearningGoal));
  void selectTimeToBecomeSkilled(OnboardOptionEntity timeToBecomeSkilled) => emit(state.copyWith(selectedTimeToBecomeSkilled: timeToBecomeSkilled));

  void startAnalysis() {
    emit(state.copyWith(status: DataCollectStatus.loading));

    // Simulate analysis progress
    Future.delayed(const Duration(milliseconds: 500), () {
      emit(
        state.copyWith(
          personalBackgroundProgress: 0.5,
          difficultiesProgress: 0.5,
          learningGoalProgress: 0.5,
          studyHabitsProgress: 0.5,
        ),
      );
    });

    Future.delayed(const Duration(seconds: 2), () {
      emit(
        state.copyWith(
          personalBackgroundProgress: 1.0,
          difficultiesProgress: 1.0,
          learningGoalProgress: 0.5,
          studyHabitsProgress: 1.0,
        ),
      );
    });

    Future.delayed(const Duration(seconds: 3), () {
      emit(
        state.copyWith(
          personalBackgroundProgress: 1.0,
          difficultiesProgress: 1.0,
          learningGoalProgress: 1.0,
          studyHabitsProgress: 1.0,
          analysisComplete: true,
          status: DataCollectStatus.success,
        ),
      );
    });
  }

  void resetAnalysis() {
    emit(
      state.copyWith(
        personalBackgroundProgress: 0.0,
        difficultiesProgress: 0.0,
        learningGoalProgress: 0.0,
        studyHabitsProgress: 0.0,
        analysisComplete: false,
      ),
    );
  }
}
