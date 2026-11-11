part of '../../onboard_v2.dart';

@lazySingleton
class OnboardV2Cubit extends Cubit<OnboardV2State> {
  OnboardV2Cubit(
    this._getOnboardingConfigUseCase,
    this._updateUserUseCase,
    this._getTaxonomyUseCase,
    this._submitAnswersUseCase,
    this._deviceInfoService,
    this._authBloc,
    this._userCubit,
    this._localeCubit,
  ) : _hasActiveAnonymousSessionOverride = null,
      _loginAnonymousSilentlyOverride = null,
      _readUserStateOverride = null,
      super(OnboardV2State.initial());

  @visibleForTesting
  OnboardV2Cubit.forTest(
    this._getOnboardingConfigUseCase,
    this._updateUserUseCase,
    this._getTaxonomyUseCase,
    this._submitAnswersUseCase,
    this._deviceInfoService,
    this._authBloc,
    this._userCubit,
    this._localeCubit, {
    bool Function()? hasActiveAnonymousSession,
    Future<bool> Function(Map<String, dynamic> payload)? loginAnonymousSilently,
    UserState Function()? readUserState,
  }) : _hasActiveAnonymousSessionOverride = hasActiveAnonymousSession,
       _loginAnonymousSilentlyOverride = loginAnonymousSilently,
       _readUserStateOverride = readUserState,
       super(OnboardV2State.initial());

  final GetOnboardingContentConfigUseCase _getOnboardingConfigUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final GetOnboardingTaxonomyUseCase _getTaxonomyUseCase;
  final SubmitOnboardingAnswersUseCase _submitAnswersUseCase;
  final IDeviceInfoService _deviceInfoService;
  final AuthBloc _authBloc;
  final UserCubit _userCubit;
  final LocaleCubit _localeCubit;
  final bool Function()? _hasActiveAnonymousSessionOverride;
  final Future<bool> Function(Map<String, dynamic> payload)? _loginAnonymousSilentlyOverride;
  final UserState Function()? _readUserStateOverride;

  int _requestSerial = 0;

  /// Bumped whenever an answer changes (câu 1/câu 2/câu 3) so a recommendation
  /// response that was already in flight for the OLD answers is dropped.
  int _recommendSerial = 0;
  bool _isSubmittingAge = false;
  Future<bool>? _anonymousSessionTask;

  /// In-flight (or completed) home-dataset prewarm. Started when the reminder
  /// screen hands off to the loading screen so the category/list-course +
  /// progress + profile calls overlap with the loading animation and the time
  /// the user spends on the result cards — instead of the handoff paying for a
  /// cold fetch on the critical path. See [prewarmHomeData].
  Future<void>? _homeInitFuture;

  Future<void> initialize() async {
    reset();
    unawaited(_ensureAnonymousSession(source: 'p1_background'));
    await Future.wait([loadOnboardData(), loadTaxonomy()]);
  }

  void reset() {
    _requestSerial += 1;
    _recommendSerial += 1;
    _isSubmittingAge = false;
    _anonymousSessionTask = null;
    _homeInitFuture = null;
    emit(OnboardV2State.initial());
  }

  Future<void> loadOnboardData() async {
    final serial = _requestSerial;
    emit(state.copyWith(onboardStatus: OnboardV2AsyncStatus.loading, onboardErrorMessage: null));

    final result = await _getOnboardingConfigUseCase(unit).run();
    if (serial != _requestSerial) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          onboardStatus: OnboardV2AsyncStatus.failure,
          onboardErrorMessage: failure.displayMessage,
        ),
      ),
      (config) => emit(
        state.copyWith(
          onboardStatus: OnboardV2AsyncStatus.success,
          onboardData: OnboardV2ConfigMapper.toOnboardEntity(config),
          showPaywallAfterOnboarding: config.showPaywallAfterOnboarding,
          reminderPresets: config.reminder.presets,
        ),
      ),
    );
  }

  /// Taxonomy (nhánh + gói) là NGUỒN DUY NHẤT của câu 1/2/3 — không còn enum dự
  /// phòng, nên lỗi/rỗng đều chuyển sang `failure` để S4 hiện Thử lại.
  Future<void> loadTaxonomy() async {
    final serial = _requestSerial;
    emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.loading, taxonomyErrorMessage: null));

    final result = await _getTaxonomyUseCase(unit).run();
    if (serial != _requestSerial) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          taxonomyStatus: OnboardV2TaxonomyStatus.failure,
          taxonomyErrorMessage: failure.displayMessage,
        ),
      ),
      (taxonomy) {
        if (taxonomy.isEmpty) {
          emit(
            state.copyWith(
              taxonomyStatus: OnboardV2TaxonomyStatus.failure,
              taxonomyErrorMessage: l10n.onboarding.onboardingV3TaxonomyLoadError,
            ),
          );
          return;
        }
        emit(state.copyWith(taxonomyStatus: OnboardV2TaxonomyStatus.success, taxonomy: taxonomy));
        _recomputeOptions();
      },
    );
  }

  void goBack() {
    final currentIndex = OnboardV2PageStep.values.indexOf(state.currentPage);
    if (currentIndex <= OnboardV2PageStep.values.indexOf(OnboardV2PageStep.p1Intro)) return;
    // Loading và Kết quả không lùi được (design.md §6.1).
    if (state.currentPage == OnboardV2PageStep.p9Loading || state.currentPage == OnboardV2PageStep.p10Result) return;

    // skipTaxonomyQuestions() nhảy thẳng S4→S7 với câu trả lời rỗng (không có
    // gói nào được chọn) — lùi từ đó phải về lại S4 (nơi có Thử lại/Bỏ qua),
    // KHÔNG được về S6, vì câu 2/câu 3 đã bị bỏ qua nên không còn gì để hiện.
    if (state.currentPage == OnboardV2PageStep.p7How && state.selectedPackageCodes.isEmpty) {
      emit(state.copyWith(currentPage: OnboardV2PageStep.p4Branches));
      return;
    }

    // Sự kiện back theo từng màn, đúng như sheet liệt kê: chỉ S3 (tuổi), S4
    // (nhánh) và S7 (màn thông tin) có back. Sheet 2026-09-18 bỏ
    // `obd_symptom_back`, nên màn Vấn đề (S5) không còn bắn gì khi lùi; và
    // `obd_infor_back` trả về đúng S7 thay vì màn Mong muốn (S6).
    final backEvent = switch (state.currentPage) {
      OnboardV2PageStep.p3Age => TrackingKey.onboardV2AgeBack,
      OnboardV2PageStep.p4Branches => TrackingKey.onboardV2PathsBack,
      OnboardV2PageStep.p7How => TrackingKey.onboardV2InforBack,
      _ => null,
    };
    if (backEvent != null) OnboardV2Tracking.track(backEvent);

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
    // Spec: obd_name_continue also persists `user_name` as a User Property
    // (same pattern as age / path_selected).
    OnboardV2Tracking.setUserProperties({'user_name': trimmedName});
    emit(state.copyWith(name: trimmedName, currentPage: OnboardV2PageStep.p3Age));
  }

  void selectAge(OnboardOptionEntity option) {
    emit(state.copyWith(selectedAge: option, p3ErrorMessage: null));
  }

  Future<void> submitAge() async {
    if (_isSubmittingAge || !state.canSubmitAge) return;

    final selectedAge = state.selectedAge;
    if (selectedAge == null) return;

    _isSubmittingAge = true;
    final serial = _requestSerial;
    final ageSheetParams = OnboardV2Tracking.ageSheetParams(selectedAge);
    OnboardV2Tracking.track(
      TrackingKey.onboardV2P3ContinueClick,
      parameters: ageSheetParams,
    );
    OnboardV2Tracking.setUserProperties({'age': ageSheetParams['age']});

    emit(
      state.copyWith(
        currentPage: OnboardV2PageStep.p4Branches,
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
      LogDev.warning('[OnboardV2Cubit] Skip background user update: anonymous session unavailable');
      return;
    }

    final currentUserId = _readUserState.user.id.trim();
    if (currentUserId.isEmpty) {
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
          LogDev.warning('[OnboardV2Cubit] background user update failed: ${failure.displayMessage}');
        },
        (_) {},
      );
    } catch (error) {
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
      // onboard_v2_anonymous_login_success/failure tracking removed per request.
      return success;
    } catch (error) {
      LogDev.warning('[OnboardV2Cubit] anonymous onboarding login failed: $error');
      return false;
    }
  }

  bool get _hasActiveAnonymousSession => (_hasActiveAnonymousSessionOverride ?? () => _authBloc.hasActiveAnonymousSession)();

  UserState get _readUserState => (_readUserStateOverride ?? () => _userCubit.state)();

  //* ---------------------------------------------------------------------
  //* Câu 1 — Lĩnh vực (S4)
  //* ---------------------------------------------------------------------

  /// Multi-select không giới hạn. GIỮ thứ tự chọn — luật câu 2 round-robin
  /// theo đúng thứ tự đó (§3.2).
  void toggleBranch(String code) {
    final next = List<String>.from(state.selectedBranchCodes);
    next.contains(code) ? next.remove(code) : next.add(code);
    OnboardV2Tracking.track(
      next.contains(code) ? TrackingKey.onboardV2PathSelect : TrackingKey.onboardV2PathUnselect,
      parameters: {'branch_code': code},
    );
    emit(state.copyWith(selectedBranchCodes: next));
    _recomputeOptions();
  }

  void continueFromP4Branches() {
    if (!state.canContinueBranches) return;
    OnboardV2Tracking.track(TrackingKey.onboardV2P5ContinueClick, parameters: OnboardV2Tracking.selectionParams(state));
    OnboardV2Tracking.setUserProperties({'path_selected': state.selectedBranchCodes.join(',')});
    emit(state.copyWith(currentPage: OnboardV2PageStep.p5Problems));
  }

  /// Lối thoát khi taxonomy lỗi hoặc rỗng (S4 hiện Thử lại + nút này bên
  /// cạnh): không còn câu 1/2/3 nào để hỏi, nên bỏ qua thẳng sang S7 với câu
  /// trả lời rỗng thay vì kẹt user ở màn không tải được. Server vẫn xếp hạng
  /// được — `OnboardingAnswerService.recommend()` tự bù đủ 3 khoá bằng
  /// `findPublishedFallback` khi có dưới 3 khoá xếp hạng theo câu trả lời —
  /// nên S10 vẫn hiện bình thường.
  void skipTaxonomyQuestions() {
    emit(
      state.copyWith(
        selectedBranchCodes: const [],
        selectedPackageCodes: const [],
        selectedDesireCode: null,
        problemOptions: const [],
        desireOptions: const [],
        currentPage: OnboardV2PageStep.p7How,
      ),
    );
  }

  //* ---------------------------------------------------------------------
  //* Câu 2 — Vấn đề (S5)
  //* ---------------------------------------------------------------------

  void togglePackage(String code) {
    if (!state.problemOptions.any((p) => p.code == code)) return;
    final next = List<String>.from(state.selectedPackageCodes);
    next.contains(code) ? next.remove(code) : next.add(code);
    emit(state.copyWith(selectedPackageCodes: next));
    _recomputeOptions();
  }

  void continueFromP5Problems() {
    if (!state.canContinueProblems) return;
    OnboardV2Tracking.track(TrackingKey.onboardV2StruggleSelect, parameters: OnboardV2Tracking.selectionParams(state));
    OnboardV2Tracking.setUserProperties({'habit_struggle': state.selectedPackageCodes.join(',')});
    emit(state.copyWith(currentPage: OnboardV2PageStep.p6Desire));
  }

  //* ---------------------------------------------------------------------
  //* Câu 3 — Mong muốn (S6)
  //* ---------------------------------------------------------------------

  void selectDesire(String code) {
    if (!state.desireOptions.any((p) => p.code == code)) return;
    emit(state.copyWith(selectedDesireCode: code));
  }

  void continueFromP6Desire() {
    if (!state.canContinueDesire) return;
    OnboardV2Tracking.track(TrackingKey.onboardV2GoalSelect, parameters: OnboardV2Tracking.selectionParams(state));
    emit(state.copyWith(currentPage: OnboardV2PageStep.p7How));
  }

  void continueFromP7How() {
    // S7 trên sheet là màn "HDDhistory giúp bạn thế nào", và `obd_infor_continue` là
    // nút Tiếp tục CỦA NÓ. Trước bản này tên ấy bị màn Mong muốn (S6) mượn
    // mất, nên S7 không bắn gì còn S6 báo cáo dưới tên của màn khác.
    OnboardV2Tracking.track(TrackingKey.onboardV2P6ContinueClick, parameters: OnboardV2Tracking.selectionParams(state));
    emit(state.copyWith(currentPage: OnboardV2PageStep.p8Reminder));
  }

  /// Gọi sau mọi thay đổi ở câu 1/câu 2: lọc lại đáp án hợp lệ, cắt lựa chọn
  /// đã mất, và huỷ gợi ý cũ (câu trả lời đổi ⇒ kết quả cũ hết giá trị).
  void _recomputeOptions() {
    final problemOptions = OnboardV2SelectionRules.problemOptions(state.taxonomy, state.selectedBranchCodes);
    final allowed = {for (final p in problemOptions) p.code};
    final packages = state.selectedPackageCodes.where(allowed.contains).toList();
    final desireOptions = OnboardV2SelectionRules.desireOptions(
      state.taxonomy,
      packages,
      seed: OnboardV2SelectionRules.seedFor(packages),
    );
    final desire = desireOptions.any((p) => p.code == state.selectedDesireCode) ? state.selectedDesireCode : null;
    _invalidateRecommendation();

    emit(
      state.copyWith(
        problemOptions: problemOptions,
        selectedPackageCodes: packages,
        desireOptions: desireOptions,
        selectedDesireCode: desire,
        recommendStatus: OnboardV2RecommendStatus.initial,
        recommendedCourses: const [],
        matchReasons: const {},
        currentCourseIndex: 0,
        recommendErrorMessage: null,
      ),
    );
  }

  void _invalidateRecommendation() {
    _recommendSerial += 1;
  }

  //* ---------------------------------------------------------------------
  //* S8 nhắc học → S9 loading → S10 kết quả
  //* ---------------------------------------------------------------------

  /// Giờ nhắc học: `HH:mm`, phút chỉ nhận bước 15 (bánh xe chỉ sinh ra 4 giá
  /// trị, guard này chặn preset/config sai định dạng).
  void setReminderTime(String hhmm) {
    if (!RegExp(r'^([01]\d|2[0-3]):(00|15|30|45)$').hasMatch(hhmm)) return;
    if (hhmm == state.reminderTime) return;
    emit(state.copyWith(reminderTime: hhmm));
    OnboardV2Tracking.track(TrackingKey.onboardV2ReminderTimeSelect, parameters: {'reminder_time': hhmm});
  }

  Future<void> submitReminder({required bool enabled, required OnboardV2NotificationStatus notificationStatus}) async {
    OnboardV2Tracking.track(
      enabled ? TrackingKey.onboardV2NotificationNotifyClick : TrackingKey.onboardV2NotificationMaybeLaterClick,
      parameters: {
        'noti_allow': enabled ? 'yes' : 'no',
        'reminder_time': enabled ? state.reminderTime : null,
      },
    );
    OnboardV2Tracking.setUserProperties({'noti_allowed': enabled ? 'yes' : 'no'});
    emit(
      state.copyWith(
        reminderEnabled: enabled,
        notificationStatus: notificationStatus,
        currentPage: OnboardV2PageStep.p9Loading,
      ),
    );
    // Prewarm the home dataset now so it is ready — or nearly ready — by the
    // time the user taps the result CTA.
    unawaited(prewarmHomeData());
    await _submitAndRecommend();
  }

  Future<void> retryRecommendation() => _submitAndRecommend();

  Future<void> _submitAndRecommend() async {
    final serial = _requestSerial;
    final recSerial = ++_recommendSerial;
    emit(state.copyWith(recommendStatus: OnboardV2RecommendStatus.loading, recommendErrorMessage: null));

    final hasSession = await _ensureAnonymousSession(source: 'p9_submit');
    if (serial != _requestSerial || recSerial != _recommendSerial) return;
    if (!hasSession) {
      _emitRecommendFallback('no_session');
      return;
    }

    final request = OnboardingAnswersRequest(
      branchCodes: state.selectedBranchCodes,
      packageCodes: state.selectedPackageCodes,
      desireCode: state.selectedDesireCode,
      reminderEnabled: state.reminderEnabled,
      reminderTime: state.reminderEnabled ? state.reminderTime : null,
      ageKey: state.selectedAge?.trackingLabel,
    );

    final result = await _submitAnswersUseCase(request).run();
    if (serial != _requestSerial || recSerial != _recommendSerial) return;

    result.fold(
      (failure) => _emitRecommendFallback(OnboardV2Tracking.exceptionReason(failure)),
      (rec) {
        if (rec.courses.isEmpty) {
          _emitRecommendFallback('empty_courses');
          return;
        }
        OnboardV2Tracking.track(
          TrackingKey.onboardV2CoursesLoaded,
          parameters: {'course_ids': rec.courses.map((course) => course.id).toList()},
        );
        emit(
          state.copyWith(
            recommendStatus: OnboardV2RecommendStatus.loaded,
            recommendedCourses: rec.courses,
            matchReasons: rec.matchReasons,
            currentCourseIndex: 0,
            recommendErrorMessage: null,
          ),
        );
      },
    );
  }

  void _emitRecommendFallback(String reason) {
    OnboardV2Tracking.track(TrackingKey.onboardV2CoursesFailure, parameters: {'reason': reason});
    emit(
      state.copyWith(
        recommendStatus: OnboardV2RecommendStatus.fallback,
        recommendErrorMessage: reason,
        recommendedCourses: const [],
        matchReasons: const {},
        currentCourseIndex: 0,
      ),
    );
  }

  /// Loading page gọi khi (đã ≥2,4s) && recommendStatus != loading — hoặc khi
  /// chạm trần 12s (kết quả sẽ hiện màn dự phòng + Thử lại).
  void finishLoading() {
    if (state.currentPage != OnboardV2PageStep.p9Loading) return;
    emit(state.copyWith(currentPage: OnboardV2PageStep.p10Result));
  }

  /// Loads the home dataset (categories/list-course, progress, profile, quote,
  /// suggestions) at most once per flow, after the anonymous session is ready.
  /// Returns the shared in-flight future so the handoff can await the SAME
  /// fetch instead of triggering a second one.
  Future<void> prewarmHomeData() => _homeInitFuture ??= _runHomePrewarm();

  Future<void> _runHomePrewarm() async {
    // initializeData hits authenticated endpoints (user progress, profile), so
    // the anonymous session must exist first. Login was already kicked off at
    // initialize(), so this usually resolves immediately.
    final hasSession = await _ensureAnonymousSession(source: 'p9_home_prewarm');
    if (!hasSession) {
      // Let a later select/retry re-attempt the prewarm rather than caching a
      // failure.
      _homeInitFuture = null;
      return;
    }
    await AppDI.injector.get<HomeCubit>().initializeData(isInit: true);
  }

  void setCurrentCourseIndex(int index) {
    if (state.recommendedCourses.isEmpty) return;
    final nextIndex = index.clamp(0, state.recommendedCourses.length - 1);
    if (nextIndex == state.currentCourseIndex) return;
    emit(state.copyWith(currentCourseIndex: nextIndex));
  }

  /// S10 → S11: user chọn khoá đầu tiên. Ghi `chosenCourseId` + `completed`
  /// lên server (fire-and-forget — không chặn UI) rồi sang màn chọn theme.
  void goToThemeWithCourse(CourseEntity course) {
    OnboardV2Tracking.track(
      TrackingKey.onboardV2CourseSelectClick,
      parameters: OnboardV2Tracking.courseSelectParams(course: course, currentCourseIndex: state.currentCourseIndex),
    );
    OnboardV2Tracking.setUserProperties({'first_course': course.id});
    unawaited(_submitAnswersUseCase(OnboardingAnswersRequest(chosenCourseId: course.id, completed: true)).run());
    emit(state.copyWith(chosenCourse: course, currentPage: OnboardV2PageStep.p11Theme));
  }

  /// S10 → S11 cho nhánh "xem kho khoá học": không có khoá được chọn.
  void goToThemeWithoutCourse() {
    unawaited(_submitAnswersUseCase(const OnboardingAnswersRequest(completed: true)).run());
    emit(state.copyWith(chosenCourse: null, currentPage: OnboardV2PageStep.p11Theme));
  }

  /// Persist `isOnboarded = true` to the server for the current (anonymous)
  /// user — AWAITED and retried. This flag is what `check-onboarding` uses to
  /// recognise a returning device after a reinstall, so it MUST actually land;
  /// the previous fire-and-forget single PATCH often didn't (app navigated away
  /// before it completed), which is why users kept re-seeing onboarding.
  /// Retries a few times, then returns regardless so a transient network
  /// failure never traps the onboarding CTA.
  Future<void> markUserOnboarded() async {
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

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        final result = await _updateUserUseCase(Map<String, dynamic>.from(payload)).run();
        if (result.isRight()) return;
        LogDev.warning('[OnboardV2Cubit] onboarded update attempt $attempt failed');
      } catch (error) {
        LogDev.warning('[OnboardV2Cubit] onboarded update attempt $attempt error: $error');
      }
      if (attempt < 3) {
        await Future<void>.delayed(Duration(milliseconds: 500 * attempt));
      }
    }
  }

  /// Fire-and-forget variant for non-blocking callers — now retried via
  /// [markUserOnboarded]. Prefer awaiting [markUserOnboarded] at the point the
  /// user actually finishes onboarding so the flag is guaranteed to land.
  void markUserOnboardedInBackground() => unawaited(markUserOnboarded());
}
