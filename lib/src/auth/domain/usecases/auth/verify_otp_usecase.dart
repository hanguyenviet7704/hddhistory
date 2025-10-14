part of '../usecases.dart';

@lazySingleton
class VerifyOtpUsecase implements UseCaseWithParams<Map<String, dynamic>, BaseResponse<AppUser>> {
  final IAuthRepository _authRepository;
  VerifyOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse<AppUser>> call(Map<String, dynamic> params) => _authRepository.verifyOTP(params);
}
