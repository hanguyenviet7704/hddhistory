part of '../usecases.dart';

@lazySingleton
class LoginSSOGoogleUsecase implements UseCaseWithoutParams<Auth> {
  final IAuthRepository _authRepository;
  LoginSSOGoogleUsecase(this._authRepository);

  @override
  TaskEither<AppException, Auth> call() => _authRepository.loginSSOGoogle();
}
