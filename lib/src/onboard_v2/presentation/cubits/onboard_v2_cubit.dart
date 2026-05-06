part of '../../onboard_v2.dart';

@lazySingleton
class OnboardV2Cubit extends Cubit<OnboardV2State> {
  OnboardV2Cubit(
    this._getAllOnboardsUseCase,
    this._getAllSkillsetsUseCase,
    this._updateUserUseCase,
    this._getAllCoursesUseCase,
    this._getCourseUseCase,
    this._deviceInfoService,
    this._authBloc,
    this._userCubit,
    this._localeCubit,
  ) : _random = Random(),
      _hasActiveAnonymousSessionOverride = null,
      _loginAnonymousSilentlyOverride = null,
      _readUserStateOverride = null,
      super(OnboardV2State.initial());

  @visibleForTesting
  OnboardV2Cubit.withRandom(
    this._getAllOnboardsUseCase,
    this._getAllSkillsetsUseCase,
    this._updateUserUseCase,
    this._getAllCoursesUseCase,
    this._getCourseUseCase,
    this._deviceInfoService,
    this._authBloc,
    this._userCubit,
    this._localeCubit,
    this._random, {
    bool Function()? hasActiveAnonymousSession,
    Future<bool> Function(Map<String, dynamic> payload)? loginAnonymousSilently,
    UserState Function()? readUserState,
  }) : _hasActiveAnonymousSessionOverride = hasActiveAnonymousSession,
       _loginAnonymousSilentlyOverride = loginAnonymousSilently,
       _readUserStateOverride = readUserState,
       super(OnboardV2State.initial());

  final GetAllOnboardsUseCase _getAllOnboardsUseCase;
  final GetAllSkillsetsUseCase _getAllSkillsetsUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final GetAllCoursesUseCase _getAllCoursesUseCase;
  final GetCourseUseCase _getCourseUseCase;
  final IDeviceInfoService _deviceInfoService;
  final AuthBloc _authBloc;
  final UserCubit _userCubit;
  final LocaleCubit _localeCubit;
  final Random _random;
  final bool Function()? _hasActiveAnonymousSessionOverride;
  final Future<bool> Function(Map<String, dynamic> payload)? _loginAnonymousSilentlyOverride;
  final UserState Function()? _readUserStateOverride;

  int _requestSerial = 0;
  bool _isSubmittingAge = false;
  bool _isLoadingRecommendation = false;
  Future<void>? _recommendationLoadTask;
  Future<void>? _skillsetLoadTask;
  Future<bool>? _anonymousSessionTask;
  int _recommendationSerial = 0;

  Future<void> initialize() async {
    reset();
    unawaited(loadSkillsets());
    await loadOnboardData();
  }

  void reset() {
    _requestSerial += 1;
    _recommendationSerial += 1;
    _isSubmittingAge = false;
    _isLoadingRecommendation = false;
    _recommendationLoadTask = null;
    _skillsetLoadTask = null;
    _anonymousSessionTask = null;
    emit(OnboardV2State.initial());
  }

  Future<void> loadOnboardData() async {
    final serial = _requestSerial;
    emit(state.copyWith(onboardStatus: OnboardV2AsyncStatus.loading, onboardErrorMessage: null));

    final result = await _getAllOnboardsUseCase(unit).run();
    if (serial != _requestSerial) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          onboardStatus: OnboardV2AsyncStatus.failure,
          onboardErrorMessage: failure.displayMessage,
        ),
      ),
      (onboardData) => emit(
        state.copyWith(
          onboardStatus: OnboardV2AsyncStatus.success,
          onboardData: onboardData,
        ),
      ),
    );
  }

  Future<void> loadSkillsets() async {
    if (state.skillsetStatus == OnboardV2AsyncStatus.success && state.skillsets.isNotEmpty) {
      return;
    }

    final activeTask = _skillsetLoadTask;
    if (activeTask != null) return activeTask;

    late final Future<void> task;
    task = _loadSkillsetsWithAnonymousSession().whenComplete(() {
      if (identical(_skillsetLoadTask, task)) {
        _skillsetLoadTask = null;
      }
    });
    _skillsetLoadTask = task;
    return task;
  }

  Future<void> _loadSkillsetsWithAnonymousSession() async {
    final serial = _requestSerial;
    if (isClosed) return;
    emit(state.copyWith(skillsetStatus: OnboardV2AsyncStatus.loading, skillsetErrorMessage: null));

    try {
      final hasSession = await _ensureAnonymousSession(source: 'p1_preload');
      if (serial != _requestSerial || isClosed) return;

      if (!hasSession) {
        emit(
          state.copyWith(
            skillsetStatus: OnboardV2AsyncStatus.failure,
            skillsetErrorMessage: l10n.onboarding.onboardingV2SkillsetLoadError,
          ),
        );
        return;
      }

      final request = PageBreakRequest<SkillsetFilterRequest>(
        filter: SkillsetFilterRequest.forOnboarding(),
      );
      final result = await _getAllSkillsetsUseCase(request).run();
      if (serial != _requestSerial || isClosed) return;

      result.fold(
        (failure) => emit(
          state.copyWith(
            skillsetStatus: OnboardV2AsyncStatus.failure,
            skillsetErrorMessage: failure.displayMessage,
          ),
        ),
        (pageData) => emit(
          state.copyWith(
            skillsetStatus: OnboardV2AsyncStatus.success,
            skillsets: pageData.items,
          ),
        ),
      );
    } catch (error) {
      if (serial != _requestSerial || isClosed) return;
      LogDev.warning('[OnboardV2Cubit] load skillsets failed: $error');
      emit(
        state.copyWith(
          skillsetStatus: OnboardV2AsyncStatus.failure,
          skillsetErrorMessage: l10n.onboarding.onboardingV2SkillsetLoadError,
        ),
      );
    }
  }

  void goBack() {
    final currentIndex = OnboardV2PageStep.values.indexOf(state.currentPage);
    if (currentIndex <= OnboardV2PageStep.values.indexOf(OnboardV2PageStep.p1Intro)) return;
    if (state.currentPage == OnboardV2PageStep.p7Recommendation) return;

    final isCancellingAgeSubmit = state.currentPage == OnboardV2PageStep.p3Age && state.p3SubmitStatus == OnboardV2AsyncStatus.loading;
    if (isCancellingAgeSubmit) {
      _requestSerial += 1;
      _isSubmittingAge = false;
    }

    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.values[currentIndex - 1],
        p3SubmitStatus: isCancellingAgeSubmit ? OnboardV2AsyncStatus.initial : state.p3SubmitStatus,
        p3ErrorMessage: isCancellingAgeSubmit ? null : state.p3ErrorMessage,
      ),
    );
  }

  void continueFromIntro() {
    OnboardV2Tracking.track(TrackingKey.onboardV2P1GetStartedClick);
    emit(state.copyWith(currentPage: OnboardV2PageStep.p2Name));
  }

  void updateName(String name) => emit(state.copyWith(name: name));

  void continueFromName() {
    final trimmedName = state.name.trim();
    if (trimmedName.isEmpty) return;
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P2ContinueClick,
      parameters: {'name_length': trimmedName.length},
    );
    emit(state.copyWith(name: trimmedName, currentPage: OnboardV2PageStep.p3Age));
  }

  void selectAge(OnboardOptionEntity option) {
    OnboardV2Tracking.track(TrackingKey.onboardV2AgeSelect, parameters: OnboardV2Tracking.ageParams(option));
    emit(state.copyWith(selectedAge: option, p3ErrorMessage: null));
  }

  Future<void> submitAge() async {
    if (_isSubmittingAge || !state.canSubmitAge) return;

    final selectedAge = state.selectedAge;
    if (selectedAge == null) return;

    _isSubmittingAge = true;
    final serial = _requestSerial;
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P3ContinueClick,
      parameters: OnboardV2Tracking.ageParams(selectedAge),
    );

    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.p4Skillset,
        p3SubmitStatus: OnboardV2AsyncStatus.success,
        p3ErrorMessage: null,
      ),
    );

    unawaited(_updateSelectedAgeInBackground(selectedAge, serial: serial));
    unawaited(loadSkillsets());
    _isSubmittingAge = false;
  }

  Future<void> _updateSelectedAgeInBackground(OnboardOptionEntity selectedAge, {required int serial}) async {
    final source = _hasActiveAnonymousSession ? 'existing_session' : 'p1_preload';
    final hasSession = await _ensureAnonymousSession(source: source);
    if (serial != _requestSerial) return;

    if (!hasSession) {
      OnboardV2Tracking.track(
        TrackingKey.onboardV2UserUpdateFailure,
        parameters: {'error_reason': 'missing_session', 'source': source},
      );
      LogDev.warning('[OnboardV2Cubit] Skip background user update: anonymous session unavailable');
      return;
    }

    final currentUserId = _readUserState.user.id.trim();
    if (currentUserId.isEmpty) {
      OnboardV2Tracking.track(
        TrackingKey.onboardV2UserUpdateFailure,
        parameters: {'error_reason': 'missing_user_id', 'source': source},
      );
      LogDev.warning('[OnboardV2Cubit] Skip background user update: missing user id');
      return;
    }

    await _updateUserProfileInBackground({
      'id': currentUserId,
      'name': state.name.trim(),
      'age': OnboardV2AgeTextResolver.resolve(selectedAge),
    }, source: source);
  }

  Future<void> _updateUserProfileInBackground(Map<String, dynamic> payload, {required String source}) async {
    try {
      final updateResult = await _updateUserUseCase(Map<String, dynamic>.from(payload)).run();
      updateResult.fold(
        (failure) {
          OnboardV2Tracking.track(
            TrackingKey.onboardV2UserUpdateFailure,
            parameters: {'error_reason': OnboardV2Tracking.exceptionReason(failure), 'source': source},
          );
          LogDev.warning('[OnboardV2Cubit] background user update failed: ${failure.displayMessage}');
        },
        (_) => OnboardV2Tracking.track(
          TrackingKey.onboardV2UserUpdateSuccess,
          parameters: {'source': source},
        ),
      );
    } catch (error) {
      OnboardV2Tracking.track(
        TrackingKey.onboardV2UserUpdateFailure,
        parameters: {'error_reason': 'unexpected', 'source': source},
      );
      LogDev.warning('[OnboardV2Cubit] background user update failed: $error');
    }
  }

  Future<bool> _ensureAnonymousSession({required String source}) async {
    if (_hasActiveAnonymousSession) return true;

    final activeTask = _anonymousSessionTask;
    if (activeTask != null) return activeTask;

    late final Future<bool> task;
    task = _loginAnonymousForOnboarding(source: source).whenComplete(() {
      if (identical(_anonymousSessionTask, task)) {
        _anonymousSessionTask = null;
      }
    });
    _anonymousSessionTask = task;
    return task;
  }

  Future<bool> _loginAnonymousForOnboarding({required String source}) async {
    try {
      final payload = buildAnonymousDeviceAuthPayload(
        deviceId: await _deviceInfoService.deviceToken,
        deviceName: await _deviceInfoService.deviceName,
        languageCode: _localeCubit.state.languageCode,
      );

      final success = await (_loginAnonymousSilentlyOverride ?? _authBloc.loginAnonymousSilently)(payload);
      OnboardV2Tracking.track(
        success ? TrackingKey.onboardV2AnonymousLoginSuccess : TrackingKey.onboardV2AnonymousLoginFailure,
        parameters: {
          'source': source,
          if (!success) 'error_reason': 'login_failed',
        },
      );
      return success;
    } catch (error) {
      OnboardV2Tracking.track(
        TrackingKey.onboardV2AnonymousLoginFailure,
        parameters: {'source': source, 'error_reason': 'unexpected'},
      );
      LogDev.warning('[OnboardV2Cubit] anonymous onboarding login failed: $error');
      return false;
    }
  }

  bool get _hasActiveAnonymousSession => (_hasActiveAnonymousSessionOverride ?? () => _authBloc.hasActiveAnonymousSession)();

  UserState get _readUserState => (_readUserStateOverride ?? () => _userCubit.state)();

  void toggleSkillset(SkillsetEntity skillset) {
    final selected = List<SkillsetEntity>.from(state.selectedSkillsets);
    final index = selected.indexWhere((item) => item.id == skillset.id);
    final isSelecting = index < 0;
    if (index >= 0) {
      selected.removeAt(index);
    } else {
      selected.add(skillset);
    }

    final mappedSelection = OnboardV2SkillsetSelectionMapper.mapSelected(selected);
    OnboardV2Tracking.track(
      isSelecting ? TrackingKey.onboardV2SkillsetSelect : TrackingKey.onboardV2SkillsetUnselect,
      parameters: OnboardV2Tracking.skillsetParams(skillset, selectedCount: mappedSelection.skillsets.length),
    );
    _recommendationSerial += 1;
    _isLoadingRecommendation = false;
    _recommendationLoadTask = null;
    emit(
      state.copyWith(
        selectedSkillsets: mappedSelection.skillsets,
        recommendationStatus: OnboardV2RecommendationStatus.initial,
        recommendationErrorMessage: null,
        recommendedCourse: null,
      ),
    );
  }

  void continueFromP4() {
    if (!state.canContinueSkillsets) return;
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P4ContinueClick,
      parameters: OnboardV2Tracking.selectedSkillsetParams(state.selectedSkillsetSelection),
    );
    emit(state.copyWith(currentPage: OnboardV2PageStep.p5Demo));
  }

  void continueFromP5() {
    OnboardV2Tracking.track(TrackingKey.onboardV2P5ContinueClick);
    emit(state.copyWith(currentPage: OnboardV2PageStep.p6Notification));
    unawaited(loadRecommendation());
  }

  Future<void> continueFromP6({OnboardV2NotificationStatus? notificationStatus}) async {
    final resolvedStatus = notificationStatus ?? state.notificationStatus;
    emit(
      state.copyWith(
        notificationStatus: resolvedStatus,
      ),
    );
    await loadRecommendation();
    if (isClosed) return;

    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.p7Recommendation,
        notificationStatus: resolvedStatus,
      ),
    );
  }

  void markUserOnboardedInBackground() {
    final user = _readUserState.user;
    final userId = user.id.trim();
    if (userId.isEmpty) {
      LogDev.warning('[OnboardV2Cubit] Skip onboarded update: missing user id');
      return;
    }

    final name = state.name.trim().isNotEmpty ? state.name.trim() : user.name.trim();
    final payload = <String, dynamic>{
      'id': userId,
      if (name.isNotEmpty) 'name': name,
      'isOnboarded': true,
    };

    unawaited(_markUserOnboarded(payload));
  }

  Future<void> _markUserOnboarded(Map<String, dynamic> payload) async {
    try {
      final result = await _updateUserUseCase(payload).run();
      result.fold(
        (failure) => LogDev.warning('[OnboardV2Cubit] onboarded update failed: ${failure.displayMessage}'),
        (_) {},
      );
    } catch (error) {
      LogDev.warning('[OnboardV2Cubit] onboarded update failed: $error');
    }
  }

  Future<void> loadRecommendation() {
    if (state.recommendationStatus == OnboardV2RecommendationStatus.loaded || state.recommendationStatus == OnboardV2RecommendationStatus.fallback) {
      return Future<void>.value();
    }

    final activeTask = _recommendationLoadTask;
    if (activeTask != null) return activeTask;

    final task = _loadRecommendation();
    _recommendationLoadTask = task;
    return task;
  }

  Future<void> _loadRecommendation() async {
    if (_isLoadingRecommendation) return;

    _isLoadingRecommendation = true;
    final serial = _requestSerial;
    final recommendationSerial = _recommendationSerial;
    emit(
      state.copyWith(
        recommendationStatus: OnboardV2RecommendationStatus.loading,
        recommendationErrorMessage: null,
        recommendedCourse: null,
      ),
    );

    try {
      final selectedIds = state.selectedSkillsetSelection.skillsetIds;
      if (selectedIds.isEmpty) {
        _emitRecommendationFallback('empty_skillsets', stage: 'list');
        return;
      }

      final listResult = await _getAllCoursesUseCase(
        PageBreakRequest<CourseFilterRequest>(
          filter: CourseFilterRequest.bySkillsets(selectedIds),
        ),
      ).run();
      if (serial != _requestSerial || recommendationSerial != _recommendationSerial) return;

      final courses = listResult.fold<List<CourseEntity>>(
        (failure) {
          _emitRecommendationFallback(OnboardV2Tracking.exceptionReason(failure), stage: 'list');
          return const [];
        },
        (pageData) => pageData.items,
      );
      if (courses.isEmpty) {
        if (state.recommendationStatus != OnboardV2RecommendationStatus.fallback) {
          _emitRecommendationFallback('empty_courses', stage: 'list');
        }
        return;
      }

      final selectedCourse = OnboardV2RandomCoursePicker.pick(courses, nextInt: _random.nextInt);
      if (selectedCourse == null || selectedCourse.id.isEmpty) {
        _emitRecommendationFallback('empty_course_id', stage: 'list');
        return;
      }

      final detailResult = await _getCourseUseCase(selectedCourse.id).run();
      if (serial != _requestSerial || recommendationSerial != _recommendationSerial) return;

      detailResult.fold(
        (failure) => _emitRecommendationFallback(OnboardV2Tracking.exceptionReason(failure), stage: 'detail'),
        (course) {
          OnboardV2Tracking.track(
            TrackingKey.onboardV2RecommendationLoaded,
            parameters: {
              'recommended_course_id': course.id,
              'recommended_course_name': course.trackingNameOrText,
              ...OnboardV2Tracking.selectedSkillsetParams(state.selectedSkillsetSelection),
            },
          );
          emit(
            state.copyWith(
              recommendationStatus: OnboardV2RecommendationStatus.loaded,
              recommendedCourse: course,
            ),
          );
        },
      );
    } catch (error) {
      if (serial == _requestSerial && recommendationSerial == _recommendationSerial) {
        _emitRecommendationFallback('unexpected', stage: 'unknown');
      }
    } finally {
      if (recommendationSerial == _recommendationSerial) {
        _isLoadingRecommendation = false;
        _recommendationLoadTask = null;
      }
    }
  }

  void _emitRecommendationFallback(String reason, {required String stage}) {
    OnboardV2Tracking.track(
      TrackingKey.onboardV2RecommendationFailure,
      parameters: {
        'error_reason': reason,
        'stage': stage,
        'fallback_primary_available': false,
      },
    );
    emit(
      state.copyWith(
        recommendationStatus: OnboardV2RecommendationStatus.fallback,
        recommendationErrorMessage: reason,
        recommendedCourse: null,
      ),
    );
  }
}
