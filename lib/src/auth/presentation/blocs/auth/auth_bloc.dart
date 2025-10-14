part of '../blocs.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocUseCaseHandlerMixin<AuthEvent, AuthState> {
  final LoginUsecase _loginUsecase;
  final LoginSSOGoogleUsecase _loginSSOGoogleUsecase;
  final LoginSSOAppleUsecase _loginSSOAppleUsecase;
  final RegisterUsecase _registerUsecase;
  final LogoutUsecase _logoutUsecase;
  final ForgotPasswordUsecase _forgotPasswordUsecase;
  final ResetPasswordUsecase _resetPasswordUsecase;
  final ResendOtpUsecase _resendOtpUsecase;
  final VerifyOtpUsecase _verifyOtpUsecase;
  final UpdatePasswordUsecase _updatePasswordUsecase;
  final DeleteAccountUsecase _deleteAccountUsecase;
  final BaseTrackingService _appTrackingService;

  AuthBloc(
    this._loginUsecase,
    this._loginSSOGoogleUsecase,
    this._loginSSOAppleUsecase,
    this._registerUsecase,
    this._logoutUsecase,
    this._forgotPasswordUsecase,
    this._resetPasswordUsecase,
    this._resendOtpUsecase,
    this._verifyOtpUsecase,
    this._updatePasswordUsecase,
    this._deleteAccountUsecase,
    @Named(DIKey.firebaseAnalyticsService) this._appTrackingService,
  ) : super(const AuthState()) {
    on<LoginEvent>(_onLogin);
    on<LoginSSOGoogleEvent>(_onLoginSSOGoogle);
    on<LoginSSOAppleEvent>(_onLoginSSOApple);
    on<RegisterEvent>(_onRegister);
    on<LogoutEvent>(_onLogout);
    on<ForgotPasswordEvent>(_onForgotPassword);
    on<ResetPasswordEvent>(_onResetPassword);
    on<ResendOTPEvent>(_onResendOTP);
    on<VerifyOTPEvent>(_onVerifyOTP);
    on<ChangePasswordEvent>(_onChangePassword);
    on<DeleteAccountPermanentlyEvent>(_onDeleteAccountPermanently);
  }

  Future<void> _successAuth(Auth response, Function() onSuccess) async {
    AppGlobalValue.accessToken = response.accessToken;
    AppGlobalValue.refreshToken = response.refreshToken;
    AppConfig.instance.context?.read<UserCubit>().setAuth(response);
    AppConfig.instance.context?.read<UserCubit>().setIsGuest(false);
    onSuccess.call();
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(state.copyWith(phone: event.email));
    await executeCustomUseCase(
      usecase: () => _loginUsecase({
        'email': event.email,
        'password': event.password,
        'data': {},
        'gotrue_meta_security': {},
        'code_challenge': null,
        'code_challenge_method': null,
        // 'device_token': await DeviceInfoService.deviceTokenStatic,
        // 'firebase_token': AppGlobalValue.firebaseToken,
      }),
      onSuccess: (response) async {
        await _successAuth(response, () => event.onSuccess?.call());
        _appTrackingService.trackEvent(
          TrackingKey.signinSigninClick,
          parameters: {
            'email': event.email,
            'status': 'success',
          },
        );
      },
      onFailure: (failure) {
        DMessage.showMessage(message: AppConfig.instance.context!.text.authIncorrectUsernameOrPassword, type: MessageType.error);
        _appTrackingService.trackEvent(
          TrackingKey.signinSigninClick,
          parameters: {
            'email': event.email,
            'status': 'failed',
          },
        );
      },
    );
  }

  Future<void> _onLoginSSOGoogle(LoginSSOGoogleEvent event, Emitter<AuthState> emit) async {
    await executeCustomUseCase(
      usecase: _loginSSOGoogleUsecase.call,
      onSuccess: (response) async => await _successAuth(response, () => event.onSuccess?.call()),
      onFailure: (failure) => DMessage.showMessage(message: AppConfig.instance.context!.text.authLoginFailedPleaseTryAgain, type: MessageType.error),
    );
  }

  Future<void> _onLoginSSOApple(LoginSSOAppleEvent event, Emitter<AuthState> emit) async {
    await executeCustomUseCase(
      usecase: _loginSSOAppleUsecase.call,
      onSuccess: (response) async => await _successAuth(response, () => event.onSuccess?.call()),
      onFailure: (failure) => DMessage.showMessage(message: AppConfig.instance.context!.text.authLoginFailedPleaseTryAgain, type: MessageType.error),
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    await executeCustomUseCase(
      usecase: () => _registerUsecase({
        'email': event.email,
        'password': event.password,
        'password_confirmation': event.passwordConfirm,
        'data': {},
        'gotrue_meta_security': {},
        'code_challenge': null,
        'code_challenge_method': null,
      }),
      onSuccess: (response) async {
        await _successAuth(response, () => event.onSuccess?.call());
        _appTrackingService.trackEvent(
          TrackingKey.signupCreateAccountClick,
          parameters: {
            'email': event.email,
            'status': 'success',
          },
        );
        AppConfig.instance.context?.read<PaywallCubit>().bonusEnergyRegisterSuccess();
      },
      onFailure: (failure) {
        DMessage.showMessage(message: AppConfig.instance.context!.text.authRegistrationFailedPleaseTryAgain, type: MessageType.error);
        _appTrackingService.trackEvent(
          TrackingKey.signupCreateAccountClick,
          parameters: {
            'email': event.email,
            'status': 'failed',
          },
        );
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await executeEmptyUseCase(
      usecase: _logoutUsecase.call,
      setLoadingState: (state, {required bool isLoading}) => state.copyWith(isLoading: isLoading),
      onSuccess: (response) async {
        _appTrackingService.trackEvent(
          TrackingKey.signinExit,
          parameters: {
            'signin_source': 'logout',
          },
        );
        AppGlobalValue.accessToken = '';
        AppGlobalValue.refreshToken = '';
        AppService.instance.resetDI();
        emit(const AuthState());
        await AppConfig.instance.context?.read<UserCubit>().clearData();

        // Reset all roadmap progress and reload tree
        // AppConfig.instance.context?.read<RoadmapCubit>().getRoadmapTree();
        AppConfig.instance.context?.read<PaywallCubit>().resetPremiumData();
        LoginRoute().push(AppConfig.instance.context!);
      },
    );
  }

  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    await executeUseCase(
      usecase: () => _forgotPasswordUsecase({'phone': event.phone}),
      onSuccess: (response) {
        _handleSuccessfulAuth(response, emit);
        emit(state.copyWith(type: VerifyType.resetPassword, phone: event.phone));
        Future.microtask(() => DNavigator.pushReplacementNamed(RouteNamed.otp));
      },
    );
  }

  Future<void> _onResetPassword(ResetPasswordEvent event, Emitter<AuthState> emit) async {
    await executeEmptyUseCase(
      usecase: () => _resetPasswordUsecase({'phone': state.phone, 'password': event.password, 'password_confirmation': event.passwordConfirm}),
      onSuccess: (response) {
        DMessage.showMessage(message: response.message);
        Future.microtask(() => LoginRoute().go(AppConfig.instance.context!));
      },
    );
  }

  Future<void> _onResendOTP(ResendOTPEvent event, Emitter<AuthState> emit) async {
    executeEmptyUseCase(
      usecase: () => _resendOtpUsecase(state.phone),
      onSuccess: (response) {
        DMessage.showMessage(message: response.message);
        _setUserPhone(emit);
      },
      onFailure: (message) => emit(state.copyWith(phone: state.phone)),
    );
  }

  void _onVerifyOTP(VerifyOTPEvent event, Emitter<AuthState> emit) async {
    executeEmptyUseCase(
      usecase: () => _verifyOtpUsecase({'type': state.type.value, 'phone': state.phone, 'otp': event.otp}),
      onSuccess: (response) {
        DMessage.showMessage(message: response.message);

        if (state.type == VerifyType.verifyAccount) {
          Future.microtask(() => LoginRoute().go(AppConfig.instance.context!));
        } else {
          Future.microtask(() => SetupPasswordRoute().go(AppConfig.instance.context!));
        }
      },
    );
  }

  void _handleSuccessfulAuth(BaseResponse<Auth> response, Emitter<AuthState> emit) {
    final Auth auth = response.data!;
    AppGlobalValue.accessToken = auth.accessToken;
    AppGlobalValue.refreshToken = auth.refreshToken;
    _setUserPhone(emit);

    DMessage.showMessage(message: response.message);
  }

  void _setUserPhone(Emitter<AuthState> emit) {
    if (state.phone.isEmpty) {
      String phone = AppConfig.instance.context!.read<UserCubit>().state.user.phone;
      emit(state.copyWith(phone: phone));
    }
  }

  FutureOr<void> _onDeleteAccountPermanently(DeleteAccountPermanentlyEvent event, Emitter<AuthState> emit) async {
    await executeEmptyUseCase(
      usecase: _deleteAccountUsecase.call,
      onSuccess: (response) {
        AppGlobalValue.accessToken = '';
        AppGlobalValue.refreshToken = '';
        AppService.instance.resetDI();
        emit(const AuthState());
        AppConfig.instance.context?.read<UserCubit>().clearData();

        Future.microtask(() => LoginRoute().push(AppConfig.instance.context!));
        _appTrackingService.trackEvent(
          TrackingKey.signinExit,
          parameters: {
            'exit_type': 'delete_account',
          },
        );
      },
    );
  }

  FutureOr<void> _onChangePassword(ChangePasswordEvent event, Emitter<AuthState> emit) async {
    await executeEmptyUseCase(
      usecase: () => _updatePasswordUsecase({'current_password': event.oldPassword, 'password': event.newPassword, 'password_confirmation': event.confirmPassword}),
      onSuccess: (response) {
        DMessage.showMessage(message: response.message);
        DNavigator.back();
        DNavigator.back();
      },
      setLoadingState: (state, {required bool isLoading}) => state.copyWith(isLoading: isLoading),
    );
  }
}
