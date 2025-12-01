// ignore_for_file: unused_field

part of '../../auth.dart';

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
    this._progressCubit,
    this._pageCubit,
    this._courseRoadmapCubit,
    this._localeCubit,
  ) : super(AuthState.initial()) {
    on<_LoginAnonymous>(_onLoginAnonymous);
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

  Future<void> _authSuccessNaviagate() async {
    bool userHaveCourseData = await _userHaveCourseData();
    if (!userHaveCourseData) {
      CourseRoute().go(AppConfig.instance.context!);
      return;
    }

    HomeRoute().go(AppConfig.instance.context!);
    _pageCubit.setCurrentIndex(0);
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

  void _loginAnonymous(Map<String, dynamic> data) {
    runUseCase(
      usecase: () => _loginAnonymousUsecase(data),
      onSuccess: (data) {
        _onAuthSuccess(data);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    _loginAnonymous(event.data);
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOGoogleUsecase(),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _authSuccessNaviagate();
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOAppleUsecase(),
      onSuccess: (data) {
        _onAuthSuccess(data);
        _authSuccessNaviagate();
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
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = _localeCubit.state.languageCode;
    runUseCase(
      usecase: () => _logoutUsecase(),
      onSuccess: (data) {
        _onResetAuth();
        _loginAnonymous({
          "device": {
            "deviceId": deviceId,
            "deviceName": deviceName,
          },
          "language": languageCode,
        });
      },
      onFailure: (error) {},
    );
  }

  Future<void> _onDeletePermanentUser(_DeleteAccountPermanently event, Emitter<AuthState> emit) async {
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = _localeCubit.state.languageCode;
    runUseCase(
      usecase: () => _deletePermanentUserUsecase(event.userId),
      onSuccess: (data) {
        _onResetAuth();
        _loginAnonymous({
          "device": {
            "deviceId": deviceId,
            "deviceName": deviceName,
          },
          "language": languageCode,
        });
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
    String deviceId = await _deviceInfoService.deviceToken;
    String deviceName = await _deviceInfoService.deviceName;
    String languageCode = _localeCubit.state.languageCode;
    _onResetAuth();
    _loginAnonymous({
      "device": {
        "deviceId": deviceId,
        "deviceName": deviceName,
      },
      "language": languageCode,
    });
  }
}
