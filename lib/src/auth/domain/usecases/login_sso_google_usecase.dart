part of '../../auth.dart';

@lazySingleton
class LoginSSOGoogleUsecase implements BaseUseCase<Unit, AuthEntity> {
  final IAuthRepository _authRepository;
  LoginSSOGoogleUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Unit _) => _authRepository.loginSSOGoogle();
}
