part of '../../auth.dart';

@lazySingleton
class LoginUsecase implements UseCaseWithParams<Map<String, dynamic>, AuthEntity> {
  final IAuthRepository _authRepository;
  LoginUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Map<String, dynamic> params) => _authRepository.login(params);
}
