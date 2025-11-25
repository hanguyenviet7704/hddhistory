part of '../../auth.dart';

@lazySingleton
class DeletePermanentUserUsecase implements UseCaseWithParams<String, BaseResponse> {
  final IAuthRepository _authRepository;
  DeletePermanentUserUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse> call(String userId) => _authRepository.deletePermanentUser(userId);
}
