part of '../blocs.dart';

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(false) bool isLoading,
    @Default(VerifyType.verifyAccount) VerifyType type,
    @Default('') String phone,
  }) = _AuthState;

  factory AuthState.initial() => const AuthState();
  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}

enum VerifyType {
  verifyAccount,
  resetPassword;

  String get value {
    return switch (this) {
      VerifyType.verifyAccount => 'verify_account',
      VerifyType.resetPassword => 'reset_password',
    };
  }
}
