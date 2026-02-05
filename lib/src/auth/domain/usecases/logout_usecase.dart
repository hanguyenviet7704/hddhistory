part of '../../auth.dart';

@lazySingleton
class LogoutUsecase implements UseCaseWithoutParams<Unit> {
  final IAuthRepository _authRepository;
  LogoutUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call() => _authRepository.logout();
}
