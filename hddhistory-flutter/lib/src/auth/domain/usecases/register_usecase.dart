part of '../../auth.dart';

@lazySingleton
class RegisterUsecase implements BaseUseCase<Map<String, dynamic>, AuthEntity> {
  final IAuthRepository _authRepository;
  RegisterUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Map<String, dynamic> params) => _authRepository.register(params);
}
