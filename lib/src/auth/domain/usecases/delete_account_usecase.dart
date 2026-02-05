part of '../../auth.dart';

@lazySingleton
class DeleteAccountUsecase implements UseCaseWithoutParams<Unit> {
  final IAuthRepository _authRepository;
  DeleteAccountUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call() => _authRepository.deleteAccount();
}
