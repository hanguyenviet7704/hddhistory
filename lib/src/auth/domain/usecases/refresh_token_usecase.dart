part of '../../auth.dart';

@lazySingleton
class RefreshTokenUsecase implements UseCaseWithParams<Map<String, dynamic>, AuthEntity> {
  final IAuthRepository _authRepository;
  RefreshTokenUsecase(this._authRepository);

  @override
  TaskEither<AppException, AuthEntity> call(Map<String, dynamic> params) => _authRepository.refreshToken(params);
}