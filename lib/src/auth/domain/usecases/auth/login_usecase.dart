part of '../usecases.dart';

@lazySingleton
class LoginUsecase implements UseCaseWithParams<Map<String, dynamic>, Auth> {
  final IAuthRepository _authRepository;
  LoginUsecase(this._authRepository);

  @override
  TaskEither<AppException, Auth> call(Map<String, dynamic> params) => _authRepository.login(params);
}
