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
  ) : super(AuthState.initial()) {
    on<_LoginAnonymous>(_onLoginAnonymous);
    on<_LoginSSOGoogle>(_onLoginSSOGoogle);
    on<_LoginSSOApple>(_onLoginSSOApple);
    on<_Register>(_onRegister);
    on<_Logout>(_onLogout);
    on<_DeleteAccountPermanently>(_onDeletePermanentUser);
  }

  void _onAuthSuccess(AuthEntity auth) {
    AppDI.injector.get<UserCubit>().setAuth(auth);
    AppGlobalValue.accessToken = auth.token.accessToken;
    AppGlobalValue.refreshToken = auth.token.refreshToken;
    AppDI.injector.get<ProfileCubit>().loadUser();
  }

  void _onResetAuth() {
    AppDI.injector.get<UserCubit>().clearData();
    AppGlobalValue.accessToken = '';
    AppGlobalValue.refreshToken = '';
    RegisterRoute().go(AppConfig.instance.context!);
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginAnonymousUsecase(event.data),
      onSuccess: (data) {
        _onAuthSuccess(data);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOGoogleUsecase(),
      onSuccess: (data) {
        _onAuthSuccess(data);
        AppDI.injector.get<LessonCubit>().loadAllLearningItems(isInit: true);
        CourseRoute().go(AppConfig.instance.context!);
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOAppleUsecase(),
      onSuccess: (data) {
        _onAuthSuccess(data);
        AppDI.injector.get<LessonCubit>().loadAllLearningItems(isInit: true);
        CourseRoute().go(AppConfig.instance.context!);
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

  FutureOr<void> _onLogout(_Logout event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _logoutUsecase(),
      onSuccess: (data) {
        _onResetAuth();
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onDeletePermanentUser(_DeleteAccountPermanently event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _deletePermanentUserUsecase(event.userId),
      onSuccess: (data) {
        _onResetAuth();
      },
      onFailure: (error) {},
    );
  }
}
