part of '../../auth.dart';

@lazySingleton
class LogoutUsecase implements UseCaseWithoutParams<BaseResponse> {
  final IAuthRepository _authRepository;
  LogoutUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse> call() => _authRepository.logout();
}
