part of '../../auth.dart';

@lazySingleton
class DeleteAccountUsecase implements BaseUseCase<Unit, Unit> {
  final IAuthRepository _authRepository;
  DeleteAccountUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(Unit _) => _authRepository.deleteAccount();
}
