part of '../../auth.dart';

@lazySingleton
class LoginSSOAppleUsecase implements UseCaseWithoutParams<Auth> {
  final IAuthRepository _authRepository;
  LoginSSOAppleUsecase(this._authRepository);

  @override
  TaskEither<AppException, Auth> call() => _authRepository.loginSSOApple();
}
