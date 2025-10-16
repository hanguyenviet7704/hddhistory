part of '../../data_collect.dart';

@lazySingleton
class DataCollectCubit extends Cubit<DataCollectState> with CubitUseCaseHandlerMixin<DataCollectState> {
  final GetAllUserCollectDatasUseCase _getAllUseCase;
  final GetUserCollectDataUseCase _getUseCase;
  final CreateUserCollectDataUseCase _createUseCase;
  final UpdateUserCollectDataUseCase _updateUseCase;
  final DeleteUserCollectDataUseCase _deleteUseCase;

  DataCollectCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._createUseCase,
    this._updateUseCase,
    this._deleteUseCase,
  ) : super(DataCollectState.initial());

  TextEditingController nameController = TextEditingController();

  Future<void> loadAllUserCollectDatas() async {
    emit(state.copyWith(status: DataCollectStatus.loading));

    final result = await _getAllUseCase().run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: DataCollectStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (items) => emit(
        state.copyWith(
          status: DataCollectStatus.success,
          items: items,
        ),
      ),
    );
  }

  Future<void> loadUserCollectData(String id) async {
    emit(state.copyWith(status: DataCollectStatus.loading));

    final result = await _getUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: DataCollectStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (item) => emit(
        state.copyWith(
          status: DataCollectStatus.success,
          selectedItem: item,
        ),
      ),
    );
  }

  Future<void> createUserCollectData(UserCollectDataEntity entity) async {
    emit(state.copyWith(status: DataCollectStatus.loading));

    final result = await _createUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: DataCollectStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (newItem) {
        final updatedItems = [...state.items, newItem];
        emit(
          state.copyWith(
            status: DataCollectStatus.success,
            items: updatedItems,
          ),
        );
      },
    );
  }

  Future<void> updateUserCollectData(UserCollectDataEntity entity) async {
    emit(state.copyWith(status: DataCollectStatus.loading));

    final result = await _updateUseCase(entity).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: DataCollectStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (updatedItem) {
        final updatedItems = state.items.map((item) => item.id == updatedItem.id ? updatedItem : item).toList();
        emit(
          state.copyWith(
            status: DataCollectStatus.success,
            items: updatedItems,
            selectedItem: updatedItem,
          ),
        );
      },
    );
  }

  Future<void> deleteUserCollectData(String id) async {
    emit(state.copyWith(status: DataCollectStatus.loading));

    final result = await _deleteUseCase(id).run();

    result.fold(
      (exception) => emit(
        state.copyWith(
          status: DataCollectStatus.failure,
          errorMessage: exception.message,
        ),
      ),
      (_) {
        final updatedItems = state.items.where((item) => item.id != id).toList();
        emit(
          state.copyWith(
            status: DataCollectStatus.success,
            items: updatedItems,
          ),
        );
      },
    );
  }

  void selectAgeRange(String ageRange) {
    emit(state.copyWith(selectedAgeRange: ageRange));
  }

  void selectGender(String gender) {
    emit(state.copyWith(selectedGender: gender));
  }

  void selectTopic(String topic) {
    final topics = List<String>.from(state.selectedTopics);
    if (topics.contains(topic)) {
      topics.remove(topic);
    } else {
      topics.add(topic);
    }
    emit(state.copyWith(selectedTopics: topics));
  }

  void toggleTopic(String topic) {
    selectTopic(topic);
  }

  void selectThisDescribeYouOption(int index, bool value) {
    final options = List<bool>.from(state.selectedThisDescribeYouOptions);
    if (index < options.length) {
      options[index] = value;
    } else {
      // Ensure the list has enough elements
      while (options.length <= index) {
        options.add(false);
      }
      options[index] = value;
    }
    emit(state.copyWith(selectedThisDescribeYouOptions: options));
  }

  void selectStruggle(String struggle) {
    final struggles = List<String>.from(state.selectedStruggles);
    if (struggles.contains(struggle)) {
      struggles.remove(struggle);
    } else {
      struggles.add(struggle);
    }
    emit(state.copyWith(selectedStruggles: struggles));
  }

  void toggleStruggle(String struggle) {
    selectStruggle(struggle);
  }

  void selectBestTimeToLearn(String bestTimeToLearn) {
    emit(state.copyWith(selectedBestTimeToLearn: bestTimeToLearn));
  }

  void selectDailyLearningGoal(String dailyLearningGoal) {
    emit(state.copyWith(selectedDailyLearningGoal: dailyLearningGoal));
  }

  void selectTimeToBecomeSkilled(String timeToBecomeSkilled) {
    emit(state.copyWith(selectedTimeToBecomeSkilled: timeToBecomeSkilled));
  }

  void selectNativeEnglishSpeaker(bool isNative) {
    emit(state.copyWith(isNativeEnglishSpeaker: isNative));
  }

  void updateUserName(String name) {
    emit(state.copyWith(userName: name));
  }

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
}
