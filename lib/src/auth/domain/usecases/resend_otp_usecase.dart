part of '../../auth.dart';

@lazySingleton
class ResendOtpUsecase implements BaseUseCase<String, Unit> {
  final IAuthRepository _authRepository;
  ResendOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(String params) => _authRepository.resendOTP(params);
}
