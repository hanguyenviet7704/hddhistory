// ignore_for_file: unused_field

part of '../../auth.dart';

enum AuthSuccessRouteDestination { course, home }

@visibleForTesting
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

  final IDeviceInfoService _deviceInfoService;
  final UserCubit _userCubit;
  final ProfileCubit _profileCubit;
  final HomeCubit _homeCubit;
  final ProgressCubit _progressCubit;
  final PageCubit _pageCubit;
  final CourseRoadmapCubit _courseRoadmapCubit;
  final LocaleCubit _localeCubit;

  static Completer<bool>? _refreshCompleter;

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
    this._deviceInfoService,
    this._userCubit,
    this._profileCubit,
    this._homeCubit,
    this._progressCubit,
    this._pageCubit,
    this._courseRoadmapCubit,
    this._localeCubit,
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
  }

  Future<bool> _userHaveCourseData() async {
    _courseRoadmapCubit.loadRoadmap();
    await _progressCubit.loadUserProgressMyCourses(isInit: true, recent: true);
    final List<CourseEntity> myCourses = _progressCubit.state.myCourses;
    return myCourses.isNotEmpty;
  }

  Future<void> _navigateAfterAuth({bool forceChooseCourseAfterLogin = false}) async {
    final destination = resolveAuthSuccessRouteDestination(
      forceChooseCourseAfterLogin: forceChooseCourseAfterLogin,
      hasCourseData: forceChooseCourseAfterLogin ? false : await _userHaveCourseData(),
    );

    switch (destination) {
      case AuthSuccessRouteDestination.course:
        await _homeCubit.initializeData(isInit: true);
        CourseRoute().go(AppConfig.instance.context!);
        return;
      case AuthSuccessRouteDestination.home:
        HomeRoute().go(AppConfig.instance.context!);
        _pageCubit.setCurrentIndex(0);
    }
  }

  void _onResetAuth() {
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

  void _loginAnonymous(
    Map<String, dynamic> data, {
    bool navigateAfterSuccess = false,
    bool forceChooseCourseAfterLogin = false,
  }) {
    runUseCase(
      usecase: () => _loginAnonymousUsecase(data),
      onSuccess: (data) {
        _onAuthSuccess(data);
        if (navigateAfterSuccess) {
          _navigateAfterAuth(forceChooseCourseAfterLogin: forceChooseCourseAfterLogin);
        }
      },
      onFailure: (error) {},
    );
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
      final result = await _loginAnonymousUsecase(data).run();
      return result.fold(
        (failure) => false,
        (auth) {
          _onAuthSuccess(auth);
          return true;
        },
      );
    } catch (error) {
      LogDev.warning('[AuthBloc] loginAnonymousSilently failed: $error');
      return false;
    }
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    _loginAnonymous(event.data);
  }

  Future<void> _onLoginAnonymousGuest(_LoginAnonymousGuest event, Emitter<AuthState> emit) async {
    final payload = await _buildAnonymousDeviceLoginPayload();
    _loginAnonymous(
      payload,
      navigateAfterSuccess: true,
      forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin,
    );
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOGoogleUsecase(unit),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _navigateAfterAuth(forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOAppleUsecase(unit),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _navigateAfterAuth(forceChooseCourseAfterLogin: event.forceChooseCourseAfterLogin);
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
    final payload = await _buildAnonymousDeviceLoginPayload();
    runUseCase(
      usecase: () => _logoutUsecase(unit),
      onSuccess: (data) {
        _onResetAuth();
        _loginAnonymous(payload);
      },
      onFailure: (error) {},
    );
  }

  Future<void> _onDeletePermanentUser(_DeleteAccountPermanently event, Emitter<AuthState> emit) async {
    final payload = await _buildAnonymousDeviceLoginPayload();
    runUseCase(
      usecase: () => _deletePermanentUserUsecase(event.userId),
      onSuccess: (data) {
        _onResetAuth();
        _loginAnonymous(payload);
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
    final payload = await _buildAnonymousDeviceLoginPayload();
    _onResetAuth();
    _loginAnonymous(payload);
  }
}
