// ignore_for_file: unused_field

part of '../../auth.dart';

@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> with BlocUseCaseHandlerMixin<AuthEvent, AuthState> {
  final LoginUsecase _loginUsecase;
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
    this._logoutUsecase,
    this._loginSSOGoogleUsecase,
    this._loginSSOAppleUsecase,
    this._registerUsecase,
    this._forgotPasswordUsecase,
    this._resetPasswordUsecase,
    this._resendOtpUsecase,
    this._deleteAccountUsecase,
  ) : super(AuthState.initial()) {
    on<_LoginSSOGoogle>(_onLoginSSOGoogle);
    on<_LoginAnonymous>(_onLoginAnonymous);
    on<_LoginSSOApple>(_onLoginSSOApple);
    on<_Register>(_onRegister);
  }
  

  FutureOr<void> _onLoginSSOGoogle(_LoginSSOGoogle event, Emitter<AuthState> emit) {
  }

  FutureOr<void> _onLoginAnonymous(_LoginAnonymous event, Emitter<AuthState> emit) {
  }

  FutureOr<void> _onLoginSSOApple(_LoginSSOApple event, Emitter<AuthState> emit) {
  }

  FutureOr<void> _onRegister(_Register event, Emitter<AuthState> emit) {
  }
}
