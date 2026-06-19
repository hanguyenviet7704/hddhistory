// ignore_for_file: unused_field

part of '../../auth.dart';

enum AuthSuccessRouteDestination { course, home }

enum RegisterGuestContinueAction { continueCurrentSession, loginAnonymousAndNavigate }

enum CourseEntryBootstrapResult { success, retryableFailure, unrecoverableFailure }

Map<String, dynamic> buildAnonymousDeviceAuthPayload({
  required String deviceId,
  required String deviceName,
  required String languageCode,
}) {
  return {
    "device": {
      "deviceId": deviceId,
      "deviceName": deviceName,
    },
    "language": languageCode,
  };
}

@visibleForTesting
AuthSuccessRouteDestination resolveAuthSuccessRouteDestination({
  required bool forceChooseCourseAfterLogin,
  required bool hasCourseData,
}) {
  if (forceChooseCourseAfterLogin || !hasCourseData) {
    return AuthSuccessRouteDestination.course;
  }

  return AuthSuccessRouteDestination.home;
}

@visibleForTesting
bool shouldConsumeFirstTimePaywallIntentAfterAuth({
  required bool showPaywallAfterAuth,
  bool hasPendingFirstTimePaywallAfterAuth = false,
}) {
  return showPaywallAfterAuth || hasPendingFirstTimePaywallAfterAuth;
}

@visibleForTesting
RegisterGuestContinueAction resolveRegisterGuestContinueAction({
  required bool hasBootstrappedGuestSession,
}) {
  if (hasBootstrappedGuestSession) {
    return RegisterGuestContinueAction.continueCurrentSession;
  }

  return RegisterGuestContinueAction.loginAnonymousAndNavigate;
}

@visibleForTesting
CourseEntryBootstrapResult resolveCourseEntryBootstrapResult(AppException? failure) {
  return switch (failure) {
    UnauthorizedException() || ForbiddenException() || InvalidInputException() => CourseEntryBootstrapResult.unrecoverableFailure,
    _ => CourseEntryBootstrapResult.retryableFailure,
  };
}

@visibleForTesting
bool isCourseEntryDataReady({
  required HomeState homeState,
  required ProgressState progressState,
  required ProfileState profileState,
}) {
  final hasCourseCatalog = homeState.status == HomeStatus.success && homeState.skillsets.any((skillset) => skillset.courses.isNotEmpty);
  final hasBlockingFailure = progressState.status == ProgressStatus.failure || profileState.status == ProfileStatus.failure;
  return hasCourseCatalog && !hasBlockingFailure;
}

@visibleForTesting
int? resolveAuthSuccessSelectedCourseTabIndex({
  required AuthSuccessRouteDestination destination,
  required bool resetToFirstCourseCategory,
}) {
  if (destination != AuthSuccessRouteDestination.course || !resetToFirstCourseCategory) {
    return null;
  }

  return 0;
}

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocUseCaseHandlerMixin<AuthEvent, AuthState> {
  final LoginUsecase _loginUsecase;
  final LoginAnonymousUsecase _loginAnonymousUsecase;
  final LogoutUsecase _logoutUsecase;
  final LoginSSOGoogleUsecase _loginSSOGoogleUsecase;
  final LoginSSOAppleUsecase _loginSSOAppleUsecase;
  final RegisterUsecase _registerUsecase;
  final ForgotPasswordUsecase _forgotPasswordUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;
  final ResendOtpUsecase _resendOtpUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final DeletePermanentUserUsecase _deletePermanentUserUsecase;
  final RefreshTokenUsecase _refreshTokenUsecase;
  final SyncHomeWidgetsUseCase _syncHomeWidgetsUseCase;
  final ClearHomeWidgetsUseCase _clearHomeWidgetsUseCase;

  final IDeviceInfoService _deviceInfoService;
  final UserCubit _userCubit;
  final ProfileCubit _profileCubit;
  final HomeCubit _homeCubit;
  final ProgressCubit _progressCubit;
  final PageCubit _pageCubit;
  final CourseRoadmapCubit _courseRoadmapCubit;
  final LocaleCubit _localeCubit;
  final IapCubit _iapCubit;

  static Completer<bool>? _refreshCompleter;
  Completer<bool>? _anonymousAuthCompleter;
  AppException? _lastAnonymousAuthFailure;

  AuthBloc(
    this._loginUsecase,
    this._loginAnonymousUsecase,
    this._logoutUsecase,
    this._loginSSOGoogleUsecase,
    this._loginSSOAppleUsecase,
    this._registerUsecase,
    this._forgotPasswordUsecase,
    this._resetPasswordUsecase,
    this._resendOtpUsecase,
    this._deleteAccountUsecase,
    this._deletePermanentUserUsecase,
    this._refreshTokenUsecase,
    this._syncHomeWidgetsUseCase,
    this._clearHomeWidgetsUseCase,
    this._deviceInfoService,
    this._userCubit,
    this._profileCubit,
    this._homeCubit,
    this._progressCubit,
    this._pageCubit,
    this._courseRoadmapCubit,
    this._localeCubit,
    this._iapCubit,
  ) : super(AuthState.initial()) {
    on<_LoginAnonymous>(_onLoginAnonymous);
    on<_LoginAnonymousGuest>(_onLoginAnonymousGuest);
    on<_LoginSSOGoogle>(_onLoginSSOGoogle);
    on<_LoginSSOApple>(_onLoginSSOApple);
    on<_Register>(_onRegister);
    on<_Logout>(_onLogout);
    on<_DeleteAccountPermanently>(_onDeletePermanentUser);
    on<_ClearSession>(_onClearSession);
  }

  void _onAuthSuccess(AuthEntity auth) {
    _userCubit.setAuth(auth);
    AppGlobalValue.accessToken = auth.token.accessToken;
    AppGlobalValue.refreshToken = auth.token.refreshToken;
    _profileCubit.loadUser();
    unawaited(_syncHomeWidgetsUseCase(HomeWidgetSyncParams(localeCode: _localeCubit.state.languageCode)).run());
  }

  Future<bool> _userHaveCourseData() async {
    _courseRoadmapCubit.loadRoadmap();
    await _progressCubit.loadUserProgressMyCourses(isInit: true, recent: true);
    final List<CourseEntity> myCourses = _progressCubit.state.myCourses;
    return myCourses.isNotEmpty;
  }

  Future<void> _navigateAfterAuth({
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
    bool resetToFirstCourseCategory = false,
  }) async {
    final hasPendingFirstTimePaywallAfterAuth = _userCubit.state.hasPendingFirstTimePaywallAfterAuth;
    if (shouldConsumeFirstTimePaywallIntentAfterAuth(
      showPaywallAfterAuth: showPaywallAfterAuth,
      hasPendingFirstTimePaywallAfterAuth: hasPendingFirstTimePaywallAfterAuth,
    )) {
      _userCubit.consumeFirstTimePaywallAfterAuthIntent();
    }

    final destination = resolveAuthSuccessRouteDestination(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      hasCourseData: forceChooseCourseAfterLogin ? false : await _userHaveCourseData(),
    );
    final selectedTabIndex = resolveAuthSuccessSelectedCourseTabIndex(
      destination: destination,
      resetToFirstCourseCategory: resetToFirstCourseCategory,
    );

    switch (destination) {
      case AuthSuccessRouteDestination.course:
        await _homeCubit.initializeData(isInit: true);
        if (selectedTabIndex != null) {
          _homeCubit.resetSelection(skillsetIndex: selectedTabIndex);
        }
        CourseRoute(selectedTabIndex: selectedTabIndex).go(AppConfig.instance.context!);
        return;
      case AuthSuccessRouteDestination.home:
        HomeRoute().go(AppConfig.instance.context!);
        _pageCubit.setCurrentIndex(0);
    }
  }

  void _onResetAuth() {
    unawaited(_clearHomeWidgetsUseCase(unit).run());
    _userCubit.clearData();
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';
    _resetAppCubits();
    RegisterRoute().go(AppConfig.instance.context!);
  }

  void _resetAppCubits() {
    _courseRoadmapCubit.reset();
    _progressCubit.reset();
  }

  bool get hasActiveAnonymousSession => _userCubit.state.user.anonymous && AppGlobalValue.accessToken.isNotEmpty;

  Future<bool> bootstrapGuestSessionForRegister() async {
    try {
      if (hasActiveAnonymousSession) {
        await _homeCubit.initializeData(isInit: true);
        return true;
      }

      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (success) {
        await _homeCubit.initializeData(isInit: true);
      }
      return success;
    } catch (error) {
      LogDev.warning('[AuthBloc] bootstrapGuestSessionForRegister failed: $error');
      return false;
    }
  }

  Future<void> warmUpCourseEntrySession() async {
    try {
      if (hasActiveAnonymousSession) return;
      final payload = await _buildAnonymousDeviceLoginPayload();
      await _authenticateAnonymousSession(payload);
    } catch (error) {
      LogDev.warning('[AuthBloc] warmUpCourseEntrySession failed: $error');
    }
  }

  Future<CourseEntryBootstrapResult> bootstrapCourseEntrySession() async {
    try {
      if (hasActiveAnonymousSession) {
        return await _initializeCourseEntryData() ? CourseEntryBootstrapResult.success : CourseEntryBootstrapResult.retryableFailure;
      }

      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (!success) {
        return resolveCourseEntryBootstrapResult(_lastAnonymousAuthFailure);
      }

      return await _initializeCourseEntryData() ? CourseEntryBootstrapResult.success : CourseEntryBootstrapResult.retryableFailure;
    } catch (error) {
      LogDev.warning('[AuthBloc] bootstrapCourseEntrySession failed: $error');
      return CourseEntryBootstrapResult.retryableFailure;
    }
  }

  Future<bool> _initializeCourseEntryData() async {
    await _homeCubit.initializeData(isInit: true);
    final isReady = isCourseEntryDataReady(
      homeState: _homeCubit.state,
      progressState: _progressCubit.state,
      profileState: _profileCubit.state,
    );
    if (!isReady) {
      LogDev.warning('[AuthBloc] Course entry data bootstrap incomplete');
      return false;
    }

    _homeCubit.resetSelection(skillsetIndex: 0);
    return true;
  }

  Future<void> continueWithCurrentGuestSession({
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) async {
    final action = resolveRegisterGuestContinueAction(
      hasBootstrappedGuestSession: hasActiveAnonymousSession,
    );

    if (action == RegisterGuestContinueAction.loginAnonymousAndNavigate) {
      final payload = await _buildAnonymousDeviceLoginPayload();
      final success = await _authenticateAnonymousSession(payload);
      if (!success) {
        return;
      }
    }

    await _navigateAfterAuth(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      showPaywallAfterAuth: showPaywallAfterAuth,
      resetToFirstCourseCategory: true,
    );
  }

  void _loginAnonymous(
    Map<String, dynamic> data, {
    bool navigateAfterSuccess = false,
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) {
    unawaited(
      _authenticateAnonymousSession(
        data,
        navigateAfterSuccess: navigateAfterSuccess,
        forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
        showPaywallAfterAuth: showPaywallAfterAuth,
      ),
    );
  }

  Future<bool> _authenticateAnonymousSession(
    Map<String, dynamic> data, {
    bool navigateAfterSuccess = false,
    bool forceChooseCourseAfterLogin = false,
    bool showPaywallAfterAuth = false,
  }) async {
    final inFlight = _anonymousAuthCompleter;
    if (inFlight != null) {
      final success = await inFlight.future;
      if (success && navigateAfterSuccess) {
        await _navigateAfterAuth(
          forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
          showPaywallAfterAuth: showPaywallAfterAuth,
        );
      }
      return success;
    }

    final completer = Completer<bool>();
    _anonymousAuthCompleter = completer;

    void complete(bool success) {
      if (!completer.isCompleted) {
        completer.complete(success);
      }
      if (identical(_anonymousAuthCompleter, completer)) {
        _anonymousAuthCompleter = null;
      }
    }

    unawaited(
      _loginAnonymousUsecase(data)
          .run()
          .then((result) {
            result.match(
              (failure) {
                _lastAnonymousAuthFailure = failure;
                complete(false);
              },
              (auth) {
                _lastAnonymousAuthFailure = null;
                _onAuthSuccess(auth);
                complete(true);
                if (navigateAfterSuccess) {
                  unawaited(
                    _navigateAfterAuth(
                      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
                      showPaywallAfterAuth: showPaywallAfterAuth,
                    ),
                  );
                }
              },
            );
          })
          .catchError((Object error) {
            LogDev.warning('[AuthBloc] Anonymous auth failed unexpectedly: $error');
            _lastAnonymousAuthFailure = const AppException.unexpected();
            complete(false);
          }),
    );

    return completer.future;
  }

  Future<Map<String, dynamic>> _buildAnonymousDeviceLoginPayload() async {
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = _localeCubit.state.languageCode;

    return buildAnonymousDeviceAuthPayload(
      deviceId: deviceId,
      deviceName: deviceName,
      languageCode: languageCode,
    );
  }

  Future<bool> loginAnonymousSilently(Map<String, dynamic> data) async {
    try {
      return await _authenticateAnonymousSession(data);
    } catch (error) {
      LogDev.warning('[AuthBloc] loginAnonymousSilently failed: $error');
      return false;
    }
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    _loginAnonymous(event.data);
  }

  Future<void> _onLoginAnonymousGuest(_LoginAnonymousGuest event, Emitter<AuthState> emit) async {
    await continueWithCurrentGuestSession(
      forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
      showPaywallAfterAuth: event.showPaywallAfterAuth,
    );
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOGoogleUsecase(unit),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _navigateAfterAuth(
          forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: event.showPaywallAfterAuth,
        );
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOAppleUsecase(unit),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _navigateAfterAuth(
          forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
          showPaywallAfterAuth: event.showPaywallAfterAuth,
        );
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onRegister(_Register event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _registerUsecase({
        "email": event.email,
        "password": event.password,
        "passwordConfirm": event.passwordConfirm,
      }),
      onSuccess: (data) {
        _onAuthSuccess(data);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLogout(_Logout event, Emitter<AuthState> emit) async {
    runUseCase(
      usecase: () => _logoutUsecase(unit),
      onSuccess: (data) {
        _onResetAuth();
        unawaited(bootstrapGuestSessionForRegister());
      },
      onFailure: (error) {},
    );
  }

  Future<void> _onDeletePermanentUser(_DeleteAccountPermanently event, Emitter<AuthState> emit) async {
    runUseCase(
      usecase: () => _deletePermanentUserUsecase(event.userId),
      onSuccess: (data) {
        _onResetAuth();
        unawaited(bootstrapGuestSessionForRegister());
      },
      onFailure: (error) {},
    );
  }

  Future<bool> refreshAccessToken() async {
    final existingCompleter = _refreshCompleter;
    if (existingCompleter != null) {
      return existingCompleter.future;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    void complete(bool value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    }

    try {
      final refreshToken = AppGlobalValue.refreshToken;
      final userId = _userCubit.state.user.id;
      String deviceId = await _deviceInfoService.deviceToken;
      String deviceName = await _deviceInfoService.deviceName;

      if (refreshToken.isEmpty || userId.isEmpty) {
        LogDev.warning('[AuthBloc] Token refresh skipped: Missing refresh token or user id');
        complete(false);
        return completer.future;
      }

      LogDev.info('[AuthBloc] Access token expired, attempting to refresh...');

      final result = await _refreshTokenUsecase({
        "userId": userId,
        "refreshToken": refreshToken,
        "device": {
          "deviceId": deviceId,
          "deviceName": deviceName,
        },
      }).run();

      final refreshed = result.match(
        (failure) {
          LogDev.error('[AuthBloc] Token refresh failed: ${failure.displayMessage}');
          return false;
        },
        (auth) {
          if (auth.token.accessToken.isEmpty) {
            LogDev.error('[AuthBloc] Token refresh failed: Empty access token returned');
            return false;
          }

          AppGlobalValue.accessToken = auth.token.accessToken;
          _userCubit.setAccessToken(auth.token.accessToken);

          LogDev.info('[AuthBloc] Token refreshed successfully, retrying original request...');
          return true;
        },
      );

      complete(refreshed);
    } catch (error, stackTrace) {
      LogDev.error('[AuthBloc] Failed to refresh token: $error\n$stackTrace');
      complete(false);
    } finally {
      _refreshCompleter = null;
    }

    return completer.future;
  }

  Future<void> _onClearSession(_ClearSession event, Emitter<AuthState> emit) async {
    _onResetAuth();
    unawaited(bootstrapGuestSessionForRegister());
  }
}
