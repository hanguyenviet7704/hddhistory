part of '../blocs.dart';

abstract class AuthEvent {}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;
  final void Function()? onSuccess;

  LoginEvent({this.email = '', this.password = '', this.onSuccess});
}

class RegisterEvent extends AuthEvent {
  final String email;
  final String password;
  final String passwordConfirm;
  final void Function()? onSuccess;

  RegisterEvent({this.email = '', this.password = '', this.passwordConfirm = '', this.onSuccess});
}

class LogoutEvent extends AuthEvent {}

class LoginSSOGoogleEvent extends AuthEvent {
  final void Function()? onSuccess;
  LoginSSOGoogleEvent({this.onSuccess});
}

class LoginSSOAppleEvent extends AuthEvent {
  final void Function()? onSuccess;
  LoginSSOAppleEvent({this.onSuccess});
}

class ForgotPasswordEvent extends AuthEvent {
  final String phone;

  ForgotPasswordEvent({this.phone = ''});
}

class ResetPasswordEvent extends AuthEvent {
  final String password;
  final String passwordConfirm;

  ResetPasswordEvent({this.password = '', this.passwordConfirm = ''});
}

class ResendOTPEvent extends AuthEvent {}

class VerifyOTPEvent extends AuthEvent {
  final String otp;

  VerifyOTPEvent({this.otp = ''});
}

class ChangePasswordEvent extends AuthEvent {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;

  ChangePasswordEvent({this.oldPassword = '', this.newPassword = '', this.confirmPassword = ''});
}

class DeleteAccountPermanentlyEvent extends AuthEvent {
  final String password;

  DeleteAccountPermanentlyEvent({this.password = ''});
}
