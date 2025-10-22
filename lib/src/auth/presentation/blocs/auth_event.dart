part of '../../auth.dart';

@freezed
sealed class AuthEvent with _$AuthEvent {
  const factory AuthEvent.login(String email, String password) = _Login;
  const factory AuthEvent.loginAnonymous() = _LoginAnonymous;
  const factory AuthEvent.loginSSOGoogle() = _LoginSSOGoogle;
  const factory AuthEvent.loginSSOApple() = _LoginSSOApple;
  const factory AuthEvent.logout() = _Logout;
  const factory AuthEvent.register(String email, String password, String passwordConfirm) = _Register;
  const factory AuthEvent.forgotPassword(String phone) = _ForgotPassword;
  const factory AuthEvent.resetPassword(String password, String passwordConfirm) = _ResetPassword;
  const factory AuthEvent.resendOTP() = _ResendOTP;
  const factory AuthEvent.verifyOTP(String otp) = _VerifyOTP;
  const factory AuthEvent.changePassword(String oldPassword, String newPassword, String confirmPassword) = _ChangePassword;
  const factory AuthEvent.deleteAccountPermanently(String password) = _DeleteAccountPermanently;
}
