part of '../../onboard_branching.dart';

enum OnboardBranchingTryNowAction {
  stay,
  goCoursePage,
  goCourseRoadmap,
}

@lazySingleton
class OnboardBranchingCubit extends Cubit<OnboardBranchingState> {
  final GetOnboardingScenarioBranchingUseCase _getUseCase;
  final Random _random = Random();
  Future<bool>? _anonymousLoginFuture;
  int _flowSessionVersion = 0;

  OnboardBranchingCubit(this._getUseCase) : super(OnboardBranchingState.initial());

  Future<void> initializeFlow({required String userName}) async {
    final cachedScenario = state.onboardScenarioData;
    final hasCachedScenario = cachedScenario.scenes.isNotEmpty;
    _flowSessionVersion += 1;
    _anonymousLoginFuture = null;

    emit(
      OnboardBranchingState.initial().copyWith(
        status: hasCachedScenario ? OnboardBranchingStatus.ready : OnboardBranchingStatus.initial,
        onboardScenarioData: cachedScenario,
        userName: userName.trim(),
        stage: OnboardBranchingStage.welcome,
        isOnboardingTransitionActive: true,
        fallbackReason: OnboardBranchingFallbackReason.none,
      ),
    );

    AppService.instance.appTrackingService.trackEvent(TrackingKey.obBranchingP1View);

    if (hasCachedScenario) {
      return;
    }

    await loadOnboardingScenarioBranching(sessionVersion: _flowSessionVersion);
  }

  Future<void> loadOnboardingScenarioBranching({int? sessionVersion}) async {
    final targetSessionVersion = sessionVersion ?? _flowSessionVersion;
    if (targetSessionVersion != _flowSessionVersion) return;
    if (state.status == OnboardBranchingStatus.loading) return;

    emit(state.copyWith(status: OnboardBranchingStatus.loading));

    final result = await _getUseCase(unit).run();
    if (targetSessionVersion != _flowSessionVersion) return;

    result.fold(
      (exception) {
        if (targetSessionVersion != _flowSessionVersion) return;
        emit(
          state.copyWith(
            status: OnboardBranchingStatus.failure,
            errorMessage: exception.message ?? 'Unknown error',
          ),
        );
      },
      (item) {
        if (targetSessionVersion != _flowSessionVersion) return;
        emit(
          state.copyWith(
            status: OnboardBranchingStatus.ready,
            onboardScenarioData: item,
          ),
        );
      },
    );
  }

  void continueFromWelcome() {
    if (state.status == OnboardBranchingStatus.loading) return;
    if (state.status == OnboardBranchingStatus.initial && state.onboardScenarioData.scenes.isEmpty) {
      unawaited(loadOnboardingScenarioBranching(sessionVersion: _flowSessionVersion));
      return;
    }

    AppService.instance.appTrackingService.trackEvent(TrackingKey.obBranchingP1Continue);
    unawaited(_triggerAnonymousLogin(force: true));
    startScenario();
  }

  void startScenario() {
    final scenario = state.onboardScenarioData;

    if (scenario.scenes.isEmpty) {
      _fallbackToNormalFlow(
        reason: state.status == OnboardBranchingStatus.failure ? OnboardBranchingFallbackReason.scenarioUnavailable : OnboardBranchingFallbackReason.scenesEmpty,
      );
      return;
    }

    final entrySceneId = scenario.entrySceneId.trim();
    if (!scenario.hasEntryScene || entrySceneId.isEmpty) {
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.entrySceneMissing);
      return;
    }
    final entryScene = scenario.getSceneById(entrySceneId);

    if (entryScene.contents.isEmpty) {
      _moveToLoadingStage();
      return;
    }

    emit(
      state.copyWith(
        stage: OnboardBranchingStage.content,
        currentSceneId: entrySceneId,
        currentContentIndex: 0,
        visitedSceneIds: [entrySceneId],
        selectedCurrentBranchOption: null,
        selectedCurrentFixedOption: null,
        selectedPersonAdmireOption: null,
        isPersonAdmireDetailVisible: false,
      ),
    );

    if (!_validateCurrentContentPayload()) {
      return;
    }

    _trackCurrentContentView();
  }

  void selectBranchOption(OnboardingScenarioBranchOptionEntity option) {
    if (!state.hasCurrentContent) return;

    emit(state.copyWith(selectedCurrentBranchOption: option));
    _trackOptionSelect(optionId: option.id.toString());
  }

  void selectFixedOption(OnboardOptionEntity option) {
    if (!state.hasCurrentContent) return;

    emit(state.copyWith(selectedCurrentFixedOption: option));
    _trackOptionSelect(optionId: option.id.toString());
  }

  void selectPersonAdmireOption(OnboardingScenarioPersonOptionEntity option) {
    if (!state.hasCurrentContent) return;

    emit(state.copyWith(selectedPersonAdmireOption: option));
    _trackOptionSelect(optionId: option.name);
  }

  void continueCurrentContent() {
    if (!state.hasCurrentContent) return;
    final content = state.currentContent;

    switch (content.type) {
      case OnboardingContentType.branch:
        _continueFromBranchContent();
        return;
      case OnboardingContentType.fixed:
        _continueFromFixedContent();
        return;
      case OnboardingContentType.personAdmire:
        _continueFromPersonAdmireContent();
        return;
      case OnboardingContentType.activation:
      case OnboardingContentType.fact:
        _goNextContent();
        return;
      case OnboardingContentType.unknown:
        _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.unknownContentType);
        return;
    }
  }

  void onLoadingCompleted() {
    if (!state.isOnLoading) return;

    emit(state.copyWith(stage: OnboardBranchingStage.recommendation));
    AppService.instance.appTrackingService.trackEvent(TrackingKey.obBranchingP7View);
    unawaited(_initializeRecommendationData(sessionVersion: _flowSessionVersion));
  }

  Future<OnboardBranchingTryNowAction> onTryNowPressed() async {
    if (state.isTryNowLoading) return OnboardBranchingTryNowAction.stay;

    emit(state.copyWith(isTryNowLoading: true, p7ErrorMessage: null));
    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.obBranchingTryNowClick,
      parameters: {'course_id': state.recommendedCourseId.isEmpty ? null : state.recommendedCourseId},
    );

    final isAuthenticated = await _ensureAnonymousSessionForTryNow();
    if (!isAuthenticated) {
      emit(state.copyWith(isTryNowLoading: false, p7ErrorMessage: _loginFailedMessage()));
      return OnboardBranchingTryNowAction.stay;
    }

    final recommendedCourseId = state.recommendedCourseId.trim();
    if (recommendedCourseId.isEmpty) {
      _completeOnboardingTransition();
      emit(state.copyWith(isTryNowLoading: false));
      return OnboardBranchingTryNowAction.goCoursePage;
    }

    final getCourseResult = await AppDI.injector.get<GetCourseUseCase>()(recommendedCourseId).run();
    final action = await getCourseResult.fold(
      (failure) async {
        _completeOnboardingTransition();
        return OnboardBranchingTryNowAction.goCoursePage;
      },
      (course) async {
        final canOpenRoadmap = await _prepareCourseHandoff(course);
        _completeOnboardingTransition();
        return canOpenRoadmap ? OnboardBranchingTryNowAction.goCourseRoadmap : OnboardBranchingTryNowAction.goCoursePage;
      },
    );

    emit(state.copyWith(isTryNowLoading: false));
    return action;
  }

  void onChooseMyselfPressed() {
    AppService.instance.appTrackingService.trackEvent(TrackingKey.obBranchingChooseMyselfClick);
    AppDI.injector.get<HomeCubit>().initializeData(isInit: true);
    _completeOnboardingTransition();
  }

  void handleUnauthorizedDuringTransition() {
    if (!state.isOnboardingTransitionActive) return;
    if (_anonymousLoginFuture != null) return;
    unawaited(_triggerAnonymousLogin(force: true));
  }

  void _continueFromBranchContent() {
    final selectedOption = state.selectedCurrentBranchOption;
    if (selectedOption == null) return;

    final updatedBranchSelections = [...state.selectedBranchOptions, selectedOption];
    final nextSceneId = selectedOption.nextSceneId.trim();

    if (nextSceneId.isEmpty) {
      emit(state.copyWith(selectedBranchOptions: updatedBranchSelections));
      _moveToLoadingStage();
      return;
    }

    if (state.visitedSceneIds.contains(nextSceneId)) {
      emit(state.copyWith(selectedBranchOptions: updatedBranchSelections));
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.sceneCycleDetected);
      return;
    }

    final nextScene = state.onboardScenarioData.getSceneById(nextSceneId);
    if (nextScene.id.isEmpty) {
      emit(state.copyWith(selectedBranchOptions: updatedBranchSelections));
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.branchNextSceneNotFound);
      return;
    }

    if (nextScene.contents.isEmpty) {
      emit(
        state.copyWith(
          selectedBranchOptions: updatedBranchSelections,
          visitedSceneIds: [...state.visitedSceneIds, nextScene.id],
        ),
      );
      _moveToLoadingStage();
      return;
    }

    emit(
      state.copyWith(
        stage: OnboardBranchingStage.content,
        currentSceneId: nextScene.id,
        currentContentIndex: 0,
        visitedSceneIds: [...state.visitedSceneIds, nextScene.id],
        selectedBranchOptions: updatedBranchSelections,
        selectedCurrentBranchOption: null,
        selectedCurrentFixedOption: null,
        selectedPersonAdmireOption: null,
        isPersonAdmireDetailVisible: false,
      ),
    );

    if (!_validateCurrentContentPayload()) {
      return;
    }

    _trackCurrentContentView();
  }

  void _continueFromFixedContent() {
    final selectedOption = state.selectedCurrentFixedOption;
    if (selectedOption == null) return;

    final options = [...state.selectedFixedOptions];
    final existedIndex = options.indexWhere((item) => item.id == selectedOption.id);
    if (existedIndex == -1) {
      options.add(selectedOption);
    } else {
      options[existedIndex] = selectedOption;
    }

    emit(state.copyWith(selectedFixedOptions: options, selectedCurrentFixedOption: null));
    _goNextContent();
  }

  void _continueFromPersonAdmireContent() {
    if (state.selectedPersonAdmireOption == null) return;

    if (!state.isPersonAdmireDetailVisible) {
      emit(state.copyWith(isPersonAdmireDetailVisible: true));
      return;
    }

    _goNextContent();
  }

  void _goNextContent() {
    if (!state.hasCurrentScene) {
      _moveToLoadingStage();
      return;
    }

    final currentScene = state.currentScene;
    if (currentScene.contents.isEmpty) {
      _moveToLoadingStage();
      return;
    }

    final nextIndex = state.currentContentIndex + 1;
    if (nextIndex >= currentScene.contents.length) {
      _moveToLoadingStage();
      return;
    }

    emit(
      state.copyWith(
        currentContentIndex: nextIndex,
        selectedCurrentBranchOption: null,
        selectedCurrentFixedOption: null,
        selectedPersonAdmireOption: null,
        isPersonAdmireDetailVisible: false,
      ),
    );

    if (!_validateCurrentContentPayload()) {
      return;
    }

    _trackCurrentContentView();
  }

  void _moveToLoadingStage() {
    emit(
      state.copyWith(
        stage: OnboardBranchingStage.loading,
        selectedCurrentBranchOption: null,
        selectedCurrentFixedOption: null,
        selectedPersonAdmireOption: null,
        isPersonAdmireDetailVisible: false,
      ),
    );
    AppService.instance.appTrackingService.trackEvent(TrackingKey.obBranchingP6View);
  }

  bool _validateCurrentContentPayload() {
    if (!state.hasCurrentContent) {
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.missingPayload);
      return false;
    }

    final content = state.currentContent;
    if (content.type == OnboardingContentType.unknown) {
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.unknownContentType);
      return false;
    }

    if (!content.hasValidPayload) {
      _fallbackToNormalFlow(reason: OnboardBranchingFallbackReason.missingPayload);
      return false;
    }

    return true;
  }

  Future<void> _initializeRecommendationData({required int sessionVersion}) async {
    if (sessionVersion != _flowSessionVersion) return;
    if (state.isRecommendationInitialized) return;

    final recommendedCourseId = state.recommendedCourseCandidateId;
    final randomPercent = 80 + _random.nextDouble() * 20;

    emit(
      state.copyWith(
        isRecommendationInitialized: true,
        recommendedCourseId: recommendedCourseId,
        recommendedProgressPercent: double.parse(randomPercent.toStringAsFixed(2)),
      ),
    );

    if (recommendedCourseId.isEmpty) return;

    final getCourseResult = await AppDI.injector.get<GetCourseUseCase>()(recommendedCourseId).run();
    if (sessionVersion != _flowSessionVersion) return;

    getCourseResult.fold(
      (failure) => null,
      (course) => emit(state.copyWith(recommendedCourse: course)),
    );
  }

  Future<bool> _prepareCourseHandoff(CourseEntity course) async {
    try {
      final homeCubit = AppDI.injector.get<HomeCubit>();
      await homeCubit.initializeData(isInit: true);
      homeCubit.selectCourseFromCourseId(course.id);
      AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(courseId: course.id);
      return true;
    } catch (error) {
      LogDev.warning('[OnboardBranchingCubit] prepareCourseHandoff failed: $error');
      return false;
    }
  }

  Future<bool> _ensureAnonymousSessionForTryNow() async {
    if (state.isAnonymousLoggedIn && AppGlobalValue.accessToken.isNotEmpty) {
      return true;
    }

    final firstAttempt = await _triggerAnonymousLogin(force: true);
    if (firstAttempt) return true;

    return _triggerAnonymousLogin(force: true);
  }

  Future<bool> _triggerAnonymousLogin({required bool force}) {
    if (!force && state.isAnonymousLoginAttempted) {
      return Future.value(state.isAnonymousLoggedIn);
    }

    final inFlight = _anonymousLoginFuture;
    if (inFlight != null) {
      return inFlight;
    }

    final task = _performAnonymousLogin(sessionVersion: _flowSessionVersion);
    _anonymousLoginFuture = task.whenComplete(() {
      _anonymousLoginFuture = null;
    });
    return _anonymousLoginFuture!;
  }

  Future<bool> _performAnonymousLogin({required int sessionVersion}) async {
    if (sessionVersion != _flowSessionVersion) return false;

    if (!state.isAnonymousLoginAttempted) {
      emit(state.copyWith(isAnonymousLoginAttempted: true));
    }

    try {
      final payload = await _buildAnonymousPayload();
      if (sessionVersion != _flowSessionVersion) return false;

      final success = await AppDI.injector.get<AuthBloc>().loginAnonymousSilently(payload);
      if (sessionVersion != _flowSessionVersion) return false;

      emit(
        state.copyWith(
          isAnonymousLoginAttempted: true,
          isAnonymousLoggedIn: success,
          shouldSkipLegacyAnonymousLogin: success,
        ),
      );
      return success;
    } catch (error) {
      LogDev.warning('[OnboardBranchingCubit] anonymous login failed: $error');
      if (sessionVersion != _flowSessionVersion) return false;
      emit(
        state.copyWith(
          isAnonymousLoginAttempted: true,
          isAnonymousLoggedIn: false,
          shouldSkipLegacyAnonymousLogin: false,
        ),
      );
      return false;
    }
  }

  Future<Map<String, dynamic>> _buildAnonymousPayload() async {
    final deviceInfoService = AppService.instance.deviceInfoService;
    final deviceId = await deviceInfoService.deviceToken;
    final deviceName = await deviceInfoService.deviceName;
    final languageCode = AppDI.injector.get<LocaleCubit>().state.languageCode;

    return {
      "device": {
        "deviceId": deviceId,
        "deviceName": deviceName,
      },
      "name": state.userName,
      "language": languageCode,
    };
  }

  void _completeOnboardingTransition() {
    AppDI.injector.get<UserCubit>().setIsUserPassOnboarding(false);
    emit(state.copyWith(isOnboardingTransitionActive: false));
  }

  void _fallbackToNormalFlow({required OnboardBranchingFallbackReason reason}) {
    final shouldSkipLegacyAnonymousLogin = state.shouldSkipLegacyAnonymousLogin && AppGlobalValue.accessToken.isNotEmpty;

    emit(
      state.copyWith(
        status: OnboardBranchingStatus.failure,
        fallbackReason: reason,
        errorMessage: reason.trackingReason,
        isOnboardingTransitionActive: false,
      ),
    );

    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.obBranchingFallback,
      parameters: {'reason': reason.trackingReason},
    );

    final dataCollectCubit = AppDI.injector.get<DataCollectCubit>();
    dataCollectCubit.setShouldSkipBranchingFlow(true);
    dataCollectCubit.setShouldSkipAnonymousLogin(shouldSkipLegacyAnonymousLogin);

    final context = AppConfig.instance.context;
    if (context != null) {
      DataCollectRoute().go(context);
    }
  }

  void _trackCurrentContentView() {
    if (!state.hasCurrentContent) return;
    final content = state.currentContent;

    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.obBranchingContentView,
      parameters: {
        'scene_id': state.currentSceneId,
        'content_index': state.currentContentIndex,
        'type': content.trackingType,
      },
    );
  }

  void _trackOptionSelect({required String optionId}) {
    if (!state.hasCurrentContent) return;
    final content = state.currentContent;

    AppService.instance.appTrackingService.trackEvent(
      TrackingKey.obBranchingOptionSelect,
      parameters: {
        'scene_id': state.currentSceneId,
        'content_index': state.currentContentIndex,
        'type': content.trackingType,
        'option_id': optionId,
      },
    );
  }

  String _loginFailedMessage() {
    final context = AppConfig.instance.context;
    if (context == null) {
      return 'Login failed, please try again.';
    }
    return context.l10n.auth.authLoginFailedPleaseTryAgain;
  }
}
