part of '../../auth.dart';

@lazySingleton
class LogoutUsecase implements BaseUseCase<Unit, Unit> {
  final IAuthRepository _authRepository;
  LogoutUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(Unit _) => _authRepository.logout();
}
