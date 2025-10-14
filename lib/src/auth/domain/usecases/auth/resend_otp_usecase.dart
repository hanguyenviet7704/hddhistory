part of '../usecases.dart';

@lazySingleton
class ResendOtpUsecase implements UseCaseWithParams<String, BaseResponse> {
  final IAuthRepository _authRepository;
  ResendOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse> call(String params) => _authRepository.resendOTP(params);
}
