part of '../../auth.dart';

@lazySingleton
class ResendOtpUsecase implements UseCaseWithParams<String, Unit> {
  final IAuthRepository _authRepository;
  ResendOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(String params) => _authRepository.resendOTP(params);
}
