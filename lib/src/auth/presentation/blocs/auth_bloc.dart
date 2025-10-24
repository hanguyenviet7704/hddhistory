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
  ) : super(AuthState.initial()) {
    on<_LoginAnonymous>(_onLoginAnonymous);
    on<_LoginSSOGoogle>(_onLoginSSOGoogle);
    on<_LoginSSOApple>(_onLoginSSOApple);
    on<_Register>(_onRegister);
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginAnonymousUsecase(event.data),
      onSuccess: (data) {
        AppDI.injector.get<UserCubit>().setAuth(data);
        AppGlobalValue.accessToken = data.token.accessToken;
        AppGlobalValue.refreshToken = data.token.refreshToken;
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOGoogleUsecase(),
      onSuccess: (data) {
        AppDI.injector.get<UserCubit>().setAuth(data);
        AppGlobalValue.accessToken = data.token.accessToken;
        AppGlobalValue.refreshToken = data.token.refreshToken;
        ExerciseRoute().go(AppConfig.instance.context!);
        AppDI.injector.get<ExerciseCubit>().loadAllLearningItems();
      },
      onFailure: (error) {},
    );
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
    runUseCase(
      usecase: () => _loginSSOAppleUsecase(),
      onSuccess: (data) {
        AppDI.injector.get<UserCubit>().setAuth(data);
        AppGlobalValue.accessToken = data.token.accessToken;
        AppGlobalValue.refreshToken = data.token.refreshToken;
        ExerciseRoute().go(AppConfig.instance.context!);
        AppDI.injector.get<ExerciseCubit>().loadAllLearningItems();
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
        AppDI.injector.get<UserCubit>().setAuth(data);
        AppGlobalValue.accessToken = data.token.accessToken;
        AppGlobalValue.refreshToken = data.token.refreshToken;
      },
      onFailure: (error) {},
    );
  }
}
