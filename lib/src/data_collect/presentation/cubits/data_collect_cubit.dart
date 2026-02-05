part of '../../data_collect.dart';

@lazySingleton
class DataCollectCubit extends Cubit<DataCollectState> with CubitUseCaseHandlerMixin<DataCollectState> {
  final IDeviceInfoService _deviceInfoService;

  DataCollectCubit(this._deviceInfoService) : super(DataCollectState.initial());

  TextEditingController nameController = TextEditingController();

  void loginAnonymous() async {
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = AppDI.injector.get<LocaleCubit>().state.languageCode;
    AppDI.injector.get<AuthBloc>().add(
      AuthEvent.loginAnonymous({
        "device": {
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
        "name": nameController.text,
        "language": languageCode,
        "age": state.selectedAgeRange?.label.text,
        "gender": state.selectedGender?.label.text,
        "onboarding": {
          "comfortableLearningTime": state.selectedComfortableLearningTime?.id,
          "dailyLearningGoal": state.selectedDailyLearningGoal?.id,
          "learningGoal": state.selectedLearningGoal?.id,
          "skillsetWantToMaster": state.selectedSkillsetsWantToMaster.map((e) => e.id).toList(),
          "learningStruggles": state.selectedLearningStruggles.map((e) => e.id).toList(),
        },
      }),
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
  void selectLearningGoal(OnboardOptionEntity learningGoal) => emit(state.copyWith(selectedLearningGoal: learningGoal));
  void selectSkillsetWantToMaster(OnboardOptionEntity skillsetWantToMaster) {
    final topics = List<OnboardOptionEntity>.from(state.selectedSkillsetsWantToMaster);
    if (topics.contains(skillsetWantToMaster)) {
      topics.remove(skillsetWantToMaster);
    } else {
      topics.add(skillsetWantToMaster);
    }
    emit(state.copyWith(selectedSkillsetsWantToMaster: topics));
  }

  void selectLearningStruggles(OnboardOptionEntity struggle) {
    final struggles = List<OnboardOptionEntity>.from(state.selectedLearningStruggles);
    if (struggles.contains(struggle)) {
      struggles.remove(struggle);
    } else {
      struggles.add(struggle);
    }
    emit(state.copyWith(selectedLearningStruggles: struggles));
  }

  void selectDailyLearningGoal(OnboardOptionEntity dailyLearningGoal) => emit(state.copyWith(selectedDailyLearningGoal: dailyLearningGoal));
  void selectComfortableLearningTime(OnboardOptionEntity comfortableLearningTime) => emit(state.copyWith(selectedComfortableLearningTime: comfortableLearningTime));

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
      ),
    );
  }
}
