part of '../../auth.dart';

@lazySingleton
class VerifyOtpUsecase implements BaseUseCase<Map<String, dynamic>, UserEntity> {
  final IAuthRepository _authRepository;
  VerifyOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, UserEntity> call(Map<String, dynamic> params) => _authRepository.verifyOTP(params);
}
