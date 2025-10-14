part of '../usecases.dart';

@lazySingleton
class DeleteAccountUsecase implements UseCaseWithoutParams<BaseResponse> {
  final IAuthRepository _authRepository;
  DeleteAccountUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse> call() => _authRepository.deleteAccount();
}
