part of '../../auth.dart';

@lazySingleton
class LoginSSOAppleUsecase implements BaseUseCase<Unit, AuthEntity> {
  final IAuthRepository _authRepository;
  LoginSSOAppleUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Unit _) => _authRepository.loginSSOApple();
}
