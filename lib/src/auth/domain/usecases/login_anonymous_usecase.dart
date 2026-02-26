part of '../../auth.dart';

@lazySingleton
class LoginAnonymousUsecase implements BaseUseCase<Map<String, dynamic>, AuthEntity> {
  final IAuthRepository _authRepository;
  LoginAnonymousUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Map<String, dynamic> params) => _authRepository.loginAnonymous(params);
}
