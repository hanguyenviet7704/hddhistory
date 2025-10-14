part of '../usecases.dart';

@lazySingleton
class RegisterUsecase implements UseCaseWithParams<Map<String, dynamic>, Auth> {
  final IAuthRepository _authRepository;
  RegisterUsecase(this._authRepository);

  @override
  TaskEither<AppException, Auth> call(Map<String, dynamic> params) => _authRepository.register(params);
}
