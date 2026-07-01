part of '../../onboard_v2.dart';

@lazySingleton
class OnboardV2Cubit extends Cubit<OnboardV2State> {
  OnboardV2Cubit(
    this._getAllOnboardsUseCase,
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
  int _courseSerial = 0;
  bool _isSubmittingAge = false;
  bool _isLoadingCourses = false;
  Future<void>? _courseLoadTask;
  Future<bool>? _anonymousSessionTask;

  /// In-flight (or completed) home-dataset prewarm. Started once the P8 course
  /// picker is reached so the skillset/list-course + progress + profile calls
  /// overlap with the time the user spends browsing recommended courses —
  /// instead of the "select course" handoff paying for a cold fetch on the
  /// critical path. See [prewarmHomeData].
  Future<void>? _homeInitFuture;

  Future<void> initialize() async {
    reset();
    unawaited(_ensureAnonymousSession(source: 'p1_background'));
    await loadOnboardData();
  }

  void reset() {
    _requestSerial += 1;
    _courseSerial += 1;
    _isSubmittingAge = false;
    _isLoadingCourses = false;
    _courseLoadTask = null;
    _anonymousSessionTask = null;
    _homeInitFuture = null;
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

  void goBack() {
    final currentIndex = OnboardV2PageStep.values.indexOf(state.currentPage);
    if (currentIndex <= OnboardV2PageStep.values.indexOf(OnboardV2PageStep.p1Intro)) return;
    if (state.currentPage == OnboardV2PageStep.p4Notification || state.currentPage == OnboardV2PageStep.p8CoursePicker) return;

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
      parameters: OnboardV2Tracking.ageSheetParams(selectedAge),
    );

    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.p4Notification,
        p3SubmitStatus: OnboardV2AsyncStatus.success,
        p3ErrorMessage: null,
      ),
    );

    unawaited(_updateSelectedAgeInBackground(selectedAge, serial: serial));
    _isSubmittingAge = false;
  }

  Future<void> _updateSelectedAgeInBackground(OnboardOptionEntity selectedAge, {required int serial}) async {
    final source = _hasActiveAnonymousSession ? 'existing_session' : 'p1_background';
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

  void continueFromP4Notification({OnboardV2NotificationStatus? notificationStatus}) {
    final resolvedStatus = notificationStatus ?? state.notificationStatus;
    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.p5PathSelection,
        notificationStatus: resolvedStatus,
      ),
    );
  }

  void togglePath(OnboardingPath path) {
    final selected = List<OnboardingPath>.from(state.selectedPaths);
    final index = selected.indexOf(path);
    final isSelecting = index < 0;

    if (isSelecting && selected.length >= 2) {
      OnboardV2Tracking.track(TrackingKey.onboardV2PathMaxReached, parameters: OnboardV2Tracking.selectedPathParams(selected));
      return;
    }

    if (index >= 0) {
      selected.removeAt(index);
    } else {
      selected.add(path);
    }

    final selectedPaths = OnboardV2SymptomSelectionMapper.dedupePaths(selected);
    final availableSymptoms = OnboardV2SymptomSelectionMapper.availableSymptoms(selectedPaths);
    final selectedSymptoms = OnboardV2SymptomSelectionMapper.retainAvailableSymptoms(
      selectedSymptoms: state.selectedSymptoms,
      availableSymptoms: availableSymptoms,
    );
    _invalidateCourses();

    OnboardV2Tracking.track(
      isSelecting ? TrackingKey.onboardV2PathSelect : TrackingKey.onboardV2PathUnselect,
      parameters: OnboardV2Tracking.pathParams(path, selectedPaths: selectedPaths),
    );

    emit(
      state.copyWith(
        selectedPaths: selectedPaths,
        availableSymptoms: availableSymptoms,
        selectedSymptoms: selectedSymptoms,
        courseStatus: OnboardV2CourseStatus.initial,
        recommendedCourses: const [],
        currentCourseIndex: 0,
        courseErrorMessage: null,
      ),
    );
  }

  void continueFromP5Paths() {
    if (!state.canContinuePaths) return;
    OnboardV2Tracking.track(TrackingKey.onboardV2P5ContinueClick, parameters: OnboardV2Tracking.selectedPathSheetParams(state.selectedPaths));
    emit(state.copyWith(currentPage: OnboardV2PageStep.p6PathMap));
  }

  void continueFromP6PathMap() {
    OnboardV2Tracking.track(TrackingKey.onboardV2P6ContinueClick, parameters: OnboardV2Tracking.selectedPathParams(state.selectedPaths));
    emit(state.copyWith(currentPage: OnboardV2PageStep.p7Symptoms));
  }

  void toggleSymptom(OnboardingSymptom symptom) {
    if (!state.availableSymptoms.contains(symptom)) return;

    final selected = List<OnboardingSymptom>.from(state.selectedSymptoms);
    final index = selected.indexOf(symptom);
    final isSelecting = index < 0;
    if (index >= 0) {
      selected.removeAt(index);
    } else {
      selected.add(symptom);
    }

    final selectedSymptoms = OnboardV2SymptomSelectionMapper.dedupeSymptoms(selected);
    _invalidateCourses();

    OnboardV2Tracking.track(
      isSelecting ? TrackingKey.onboardV2SymptomSelect : TrackingKey.onboardV2SymptomUnselect,
      parameters: OnboardV2Tracking.symptomParams(symptom, selectedSymptoms: selectedSymptoms),
    );

    emit(
      state.copyWith(
        selectedSymptoms: selectedSymptoms,
        courseStatus: OnboardV2CourseStatus.initial,
        recommendedCourses: const [],
        currentCourseIndex: 0,
        courseErrorMessage: null,
      ),
    );
  }

  Future<void> continueFromP7Symptoms() async {
    if (!state.canContinueSymptoms) return;
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P7ContinueClick,
      parameters: OnboardV2Tracking.pathRelateSheetParams(
        selectedPaths: state.selectedPaths,
        selectedSymptoms: state.selectedSymptoms,
      ),
    );
    emit(state.copyWith(currentPage: OnboardV2PageStep.p8CoursePicker));
    // Prewarm the home dataset now (in parallel with the course-list fetch) so
    // it is ready — or nearly ready — by the time the user taps "select".
    unawaited(prewarmHomeData());
    await loadCoursesForP8(force: true);
  }

  /// Loads the home dataset (skillsets/list-course, progress, profile, quote,
  /// suggestions) at most once per flow, after the anonymous session is ready.
  /// Returns the shared in-flight future so the handoff can await the SAME
  /// fetch instead of triggering a second one.
  Future<void> prewarmHomeData() => _homeInitFuture ??= _runHomePrewarm();

  Future<void> _runHomePrewarm() async {
    // initializeData hits authenticated endpoints (user progress, profile), so
    // the anonymous session must exist first. Login was already kicked off at
    // initialize(), so this usually resolves immediately.
    final hasSession = await _ensureAnonymousSession(source: 'p8_home_prewarm');
    if (!hasSession) {
      // Let a later select/retry re-attempt the prewarm rather than caching a
      // failure.
      _homeInitFuture = null;
      return;
    }
    await AppDI.injector.get<HomeCubit>().initializeData(isInit: true);
  }

  Future<void> retryCoursesForP8() => loadCoursesForP8(force: true);

  Future<void> loadCoursesForP8({bool force = false}) {
    if (!force && (state.courseStatus == OnboardV2CourseStatus.loaded || state.courseStatus == OnboardV2CourseStatus.fallback)) {
      return Future<void>.value();
    }

    final activeTask = _courseLoadTask;
    if (activeTask != null) return activeTask;

    late final Future<void> task;
    task = _loadCoursesForP8().whenComplete(() {
      if (identical(_courseLoadTask, task)) {
        _courseLoadTask = null;
      }
    });
    _courseLoadTask = task;
    return task;
  }

  Future<void> _loadCoursesForP8() async {
    if (_isLoadingCourses) return;
    final selectedSymptoms = List<OnboardingSymptom>.from(state.selectedSymptoms);
    if (selectedSymptoms.isEmpty) {
      _emitCoursesFallback('empty_symptoms', stage: 'list');
      return;
    }

    _isLoadingCourses = true;
    final serial = _requestSerial;
    final courseSerial = _courseSerial;
    emit(
      state.copyWith(
        courseStatus: OnboardV2CourseStatus.loading,
        courseErrorMessage: null,
        recommendedCourses: const [],
        currentCourseIndex: 0,
      ),
    );

    try {
      final listResult = await _getAllCoursesUseCase(
        PageBreakRequest<CourseFilterRequest>(
          filter: CourseFilterRequest.byOnboardingSymptoms(selectedSymptoms),
        ),
      ).run();
      if (serial != _requestSerial || courseSerial != _courseSerial) return;

      final courses = listResult.fold<List<CourseEntity>?>(
        (failure) {
          _emitCoursesFallback(OnboardV2Tracking.exceptionReason(failure), stage: 'list');
          return null;
        },
        (pageData) => pageData.items,
      );
      if (courses == null) return;

      final pickedCourses = OnboardV2RandomCoursePicker.pick(courses, nextInt: _random.nextInt);
      if (pickedCourses.isEmpty) {
        _emitCoursesFallback('empty_courses', stage: 'list');
        return;
      }

      OnboardV2Tracking.track(
        TrackingKey.onboardV2CoursesLoaded,
        parameters: OnboardV2Tracking.coursesLoadedParams(
          courses: pickedCourses,
          selectedSymptoms: selectedSymptoms,
        ),
      );
      emit(
        state.copyWith(
          courseStatus: OnboardV2CourseStatus.loaded,
          recommendedCourses: pickedCourses,
          currentCourseIndex: 0,
          courseErrorMessage: null,
        ),
      );
    } catch (error) {
      if (serial == _requestSerial && courseSerial == _courseSerial) {
        _emitCoursesFallback('unexpected', stage: 'unknown');
      }
    } finally {
      if (courseSerial == _courseSerial) {
        _isLoadingCourses = false;
      }
    }
  }

  void setCurrentCourseIndex(int index) {
    if (state.recommendedCourses.isEmpty) return;
    final nextIndex = index.clamp(0, state.recommendedCourses.length - 1);
    if (nextIndex == state.currentCourseIndex) return;
    emit(state.copyWith(currentCourseIndex: nextIndex));
  }

  Future<CourseEntity?> resolveCourseForHandoff(CourseEntity course) async {
    final courseId = course.id.trim();
    if (courseId.isEmpty) return null;
    final serial = _requestSerial;
    final courseSerial = _courseSerial;
    emit(state.copyWith(navigationStatus: OnboardV2NavigationStatus.loading, navigationErrorMessage: null));

    try {
      final result = await _getCourseUseCase(courseId).run();
      if (serial != _requestSerial || courseSerial != _courseSerial) return null;

      return result.fold(
        (failure) {
          _emitCoursesFallback(OnboardV2Tracking.exceptionReason(failure), stage: 'detail');
          emit(
            state.copyWith(
              navigationStatus: OnboardV2NavigationStatus.failure,
              navigationErrorMessage: failure.displayMessage,
            ),
          );
          return null;
        },
        (detail) {
          emit(state.copyWith(navigationStatus: OnboardV2NavigationStatus.success));
          return detail.id.trim().isEmpty ? course : detail;
        },
      );
    } catch (error) {
      if (serial == _requestSerial && courseSerial == _courseSerial) {
        _emitCoursesFallback('unexpected', stage: 'detail');
        emit(
          state.copyWith(
            navigationStatus: OnboardV2NavigationStatus.failure,
            navigationErrorMessage: l10n.onboarding.onboardingV2GenericError,
          ),
        );
      }
      return null;
    }
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

  void _emitCoursesFallback(String reason, {required String stage}) {
    OnboardV2Tracking.track(
      TrackingKey.onboardV2CoursesFailure,
      parameters: {
        ...OnboardV2Tracking.selectedSymptomParams(state.selectedSymptoms),
        'error_reason': reason,
        'stage': stage,
      },
    );
    emit(
      state.copyWith(
        courseStatus: OnboardV2CourseStatus.fallback,
        courseErrorMessage: reason,
        recommendedCourses: const [],
        currentCourseIndex: 0,
      ),
    );
  }

  void _invalidateCourses() {
    _courseSerial += 1;
    _isLoadingCourses = false;
    _courseLoadTask = null;
  }
}
