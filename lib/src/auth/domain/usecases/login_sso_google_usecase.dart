part of '../../auth.dart';

@lazySingleton
class LoginSSOGoogleUsecase implements UseCaseWithoutParams<AuthEntity> {
  final IAuthRepository _authRepository;
  LoginSSOGoogleUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call() => _authRepository.loginSSOGoogle();
}
