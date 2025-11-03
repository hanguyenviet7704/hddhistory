part of '../../auth.dart';

enum AuthStatus { initial, loading, success, failure }

@freezed
abstract class AuthState with _$AuthState {
  const factory AuthState({
    @Default(AuthStatus.initial) AuthStatus status,
    String? errorMessage,
  }) = _AuthState;

  factory AuthState.initial() => AuthState();

  factory AuthState.fromJson(Map<String, dynamic> json) => _$AuthStateFromJson(json);
}
