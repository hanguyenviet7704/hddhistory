part of '../../auth.dart';

@lazySingleton
class LoginSSOAppleUsecase implements BaseUseCase<String?, AuthEntity> {
  final IAuthRepository _authRepository;
  LoginSSOAppleUsecase(this._authRepository);

  /// [params] = the current guest's userId (or null), so the backend can
  /// upgrade THAT guest in place and preserve its progress.
  @override
  TaskEither<AppException, AuthEntity> call(String? params) => _authRepository.loginSSOApple(anonymousUserId: params);
}
