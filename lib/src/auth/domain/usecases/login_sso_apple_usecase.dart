part of '../../auth.dart';

@lazySingleton
class LoginSSOAppleUsecase implements UseCaseWithoutParams<AuthEntity> {
  final IAuthRepository _authRepository;
  LoginSSOAppleUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call() => _authRepository.loginSSOApple();
}
