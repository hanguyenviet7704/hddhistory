part of '../../daily_warm_up.dart';

@lazySingleton
class DailyWarmUpCubit extends Cubit<DailyWarmUpState> with CubitUseCaseHandlerMixin<DailyWarmUpState> {
  final GetDailyWarmUpUseCase _getUseCase;
  final DailyWarmUpLocalDataSource _localDataSource;
  final GetCourseUseCase _getCourseUseCase;

  DailyWarmUpCubit(this._getUseCase, this._localDataSource, this._getCourseUseCase) : super(DailyWarmUpState.initial());

  void loadDailyWarmUp() async {
    await runUseCase<DailyWarmUpEntity>(
      usecase: () => _getUseCase(unit),
      buildLoadingState: () => state.copyWith(status: DailyWarmUpStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: DailyWarmUpStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: DailyWarmUpStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }

  Future<bool> loadForHomeEntry({
    required String userId,
    required String localDate,
    required bool hasCompletedOnboarding,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedDate = localDate.trim();
    if (normalizedUserId.isEmpty || normalizedDate.isEmpty || state.isCheckingEntry || state.isPresenting) {
      await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'home_not_active');
      return false;
    }

    if (!hasCompletedOnboarding) {
      await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'onboarding_not_completed');
      return false;
    }

    await trackDailyWarmUpEntryCheck(source: 'home_open', shownDate: normalizedDate);
    if (await _shouldSkipForOnboardingCompletionDate(normalizedUserId, normalizedDate)) {
      await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'first_post_onboarding_day');
      return false;
    }

    final shownDate = await _localDataSource.getShownDate(normalizedUserId);
    if (shownDate == normalizedDate) {
      await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'already_shown_today');
      return false;
    }

    emit(
      state.copyWith(
        status: DailyWarmUpStatus.loading,
        isCheckingEntry: true,
        errorMessage: null,
        shownUserId: normalizedUserId,
        shownDate: normalizedDate,
      ),
    );

    final result = await _getUseCase(unit).run();
    return await result.fold(
      (error) async {
        emit(state.copyWith(status: DailyWarmUpStatus.closed, isCheckingEntry: false, isPresenting: false));
        await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'api_failure');
        return false;
      },
      (entity) async {
        final usableQuestions = filterUsableDailyWarmUpQuestions(entity.questions);
        if (entity.suggestedCourseId.trim().isEmpty) {
          emit(state.copyWith(status: DailyWarmUpStatus.closed, isCheckingEntry: false, isPresenting: false));
          await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'empty_suggested_course_id');
          return false;
        }

        if (usableQuestions.isEmpty) {
          emit(state.copyWith(status: DailyWarmUpStatus.closed, isCheckingEntry: false, isPresenting: false));
          await trackDailyWarmUpSkip(source: 'home_open', skipReason: 'no_usable_questions');
          return false;
        }

        emit(
          state.copyWith(
            status: DailyWarmUpStatus.entry,
            entity: entity,
            selectedItem: entity,
            usableQuestions: usableQuestions,
            currentQuestionIndex: 0,
            results: const [],
            latestResult: null,
            suggestedCourse: null,
            isCheckingEntry: false,
            isPresenting: true,
            isLoadingCourse: false,
            isRoutingToRoadmap: false,
            hasMarkedShown: false,
            hasTrackedCompleteView: false,
            errorMessage: null,
            selectedAnswerIndex: -1,
            selectedAnswersIndices: const {},
            orderedOptionIds: const [],
            placedOptionIds: const {},
            selectedWordIndices: const {},
          ),
        );
        return true;
      },
    );
  }

  Future<void> markEntryPresented() async {
    if (state.hasMarkedShown || state.shownUserId.isEmpty || state.shownDate.isEmpty) return;
    await _localDataSource.markShownDate(state.shownUserId, state.shownDate);
    emit(state.copyWith(hasMarkedShown: true));
    await trackDailyWarmUpP1View();
  }

  Future<void> dismissEntry() async {
    await markEntryPresented();
    await trackDailyWarmUpMaybeLaterClick();
    closeFlow();
  }

  void startWarmUp() {
    if (!state.canShowEntry) return;
    trackDailyWarmUpStartClick();
    emit(_clearCurrentAnswer(state.copyWith(status: DailyWarmUpStatus.question)));
    trackCurrentQuestionView();
  }

  void closeFlow() {
    if (state.status == DailyWarmUpStatus.question || state.status == DailyWarmUpStatus.result) {
      trackDailyWarmUpExitClick();
    }
    emit(
      state.copyWith(
        status: DailyWarmUpStatus.closed,
        isPresenting: false,
        isCheckingEntry: false,
        isLoadingCourse: false,
        isRoutingToRoadmap: false,
      ),
    );
  }

  void selectChoiceAnswer(int index) {
    final question = state.currentQuestion;
    if (question == null || state.latestResult != null) return;
    AppHaptic.select();

    if (question.typedPayload is QuestionMultipleChoicePayloadEntity) {
      final selected = Set<int>.from(state.selectedAnswersIndices);
      if (selected.contains(index)) {
        selected.remove(index);
      } else {
        selected.add(index);
      }
      emit(state.copyWith(selectedAnswersIndices: selected));
      return;
    }

    emit(state.copyWith(selectedAnswerIndex: index));
  }

  void setOrderedOptionIds(List<int> optionIds) {
    if (state.latestResult != null) return;
    emit(state.copyWith(orderedOptionIds: List<int>.from(optionIds)));
  }

  void placeOption({required int slotIndex, required int optionId}) {
    if (state.latestResult != null) return;
    final placed = Map<int, int>.from(state.placedOptionIds);
    placed.removeWhere((key, value) => key == slotIndex || value == optionId);
    placed[slotIndex] = optionId;
    emit(state.copyWith(placedOptionIds: placed));
  }

  void removePlacedOption(int slotIndex) {
    if (state.latestResult != null) return;
    final placed = Map<int, int>.from(state.placedOptionIds)..remove(slotIndex);
    emit(state.copyWith(placedOptionIds: placed));
  }

  void toggleWordIndex(int index) {
    if (state.latestResult != null) return;
    AppHaptic.select();
    final selected = Set<int>.from(state.selectedWordIndices);
    if (selected.contains(index)) {
      selected.remove(index);
    } else {
      selected.add(index);
    }
    emit(state.copyWith(selectedWordIndices: selected));
  }

  Future<DailyWarmUpAnswerResultEntity?> checkCurrentQuestion() async {
    final question = state.currentQuestion;
    if (question == null || !state.canCheckCurrentQuestion) return null;

    await trackDailyWarmUpQuestionCheckClick(question);
    final result = evaluateDailyWarmUpQuestion(
      question,
      questionIndex: state.currentQuestionIndex,
      selectedAnswerIndex: state.selectedAnswerIndex,
      selectedAnswersIndices: state.selectedAnswersIndices,
      orderedOptionIds: state.orderedOptionIds,
      placedOptionIds: state.placedOptionIds,
      selectedWordIndices: state.selectedWordIndices,
    );
    result.isCorrect ? AppHaptic.success() : AppHaptic.error();
    emit(
      state.copyWith(
        status: DailyWarmUpStatus.result,
        latestResult: result,
        results: [...state.results, result],
      ),
    );
    await trackDailyWarmUpQuestionResultView(result);
    return result;
  }

  Future<void> continueFromResult() async {
    final result = state.latestResult;
    if (result == null) return;
    await trackDailyWarmUpQuestionContinueClick(result);

    if (state.isFinalQuestion) {
      showCompletion();
      return;
    }

    emit(
      _clearCurrentAnswer(
        state.copyWith(
          status: DailyWarmUpStatus.question,
          currentQuestionIndex: state.currentQuestionIndex + 1,
          latestResult: null,
        ),
      ),
    );
    await trackCurrentQuestionView();
  }

  void showCompletion() {
    emit(_clearCurrentAnswer(state.copyWith(status: DailyWarmUpStatus.completion, latestResult: null)));
    if (!state.hasTrackedCompleteView) {
      trackDailyWarmUpCompleteView();
      emit(state.copyWith(hasTrackedCompleteView: true));
    }
  }

  Future<void> loadSuggestedCourse() async {
    final courseId = state.entity?.suggestedCourseId.trim() ?? '';
    if (courseId.isEmpty) {
      await trackDailyWarmUpRouteFailure(failureStage: 'get_course');
      closeFlow();
      return;
    }

    emit(state.copyWith(isLoadingCourse: true));
    final result = await _getCourseUseCase(courseId).run();
    result.fold(
      (error) {
        trackDailyWarmUpRouteFailure(failureStage: 'get_course');
        emit(state.copyWith(status: DailyWarmUpStatus.closed, isPresenting: false, isLoadingCourse: false));
      },
      (course) {
        if (course.id.trim().isEmpty) {
          trackDailyWarmUpRouteFailure(failureStage: 'get_course');
          emit(state.copyWith(status: DailyWarmUpStatus.closed, isPresenting: false, isLoadingCourse: false));
          return;
        }
        emit(state.copyWith(suggestedCourse: course, isLoadingCourse: false));
      },
    );
  }

  Future<bool> startTodayLesson({
    Future<CourseHandoffRouteIntent> Function(CourseEntity course)? prepareCourse,
  }) async {
    if (state.isRoutingToRoadmap) return false;
    final course = state.suggestedCourse;
    if (course == null) return false;

    emit(state.copyWith(isRoutingToRoadmap: true));
    await trackDailyWarmUpStartLessonClick();
    final intent = await (prepareCourse ?? (course) => const CourseHandoffHelper().prepareRecommendedCourse(course: course))(course);
    final canRoute = intent == CourseHandoffRouteIntent.courseRoadmap;
    if (!canRoute) {
      await trackDailyWarmUpRouteFailure(failureStage: 'load_roadmap');
    }
    emit(state.copyWith(isRoutingToRoadmap: false));
    return canRoute;
  }

  Future<void> exploreMore() async {
    await trackDailyWarmUpExploreMoreClick();
    closeFlow();
  }

  DailyWarmUpState _clearCurrentAnswer(DailyWarmUpState input) {
    return input.copyWith(
      selectedAnswerIndex: -1,
      selectedAnswersIndices: const {},
      orderedOptionIds: const [],
      placedOptionIds: const {},
      selectedWordIndices: const {},
    );
  }

  Future<bool> _shouldSkipForOnboardingCompletionDate(String userId, String localDate) async {
    final completedDate = await _localDataSource.getOnboardingCompletedDate(userId);
    if (completedDate.trim().isEmpty) {
      await _localDataSource.markOnboardingCompletedDateIfAbsent(userId, localDate);
      return true;
    }
    return completedDate.trim() == localDate;
  }
}
