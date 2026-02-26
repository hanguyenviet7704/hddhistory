part of '../../auth.dart';

@lazySingleton
class DeletePermanentUserUsecase implements BaseUseCase<String, Unit> {
  final IAuthRepository _authRepository;
  DeletePermanentUserUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(String userId) => _authRepository.deletePermanentUser(userId);
}
