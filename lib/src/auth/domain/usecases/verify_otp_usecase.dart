part of '../../auth.dart';

@lazySingleton
class VerifyOtpUsecase implements UseCaseWithParams<Map<String, dynamic>, BaseResponse<UserModel>> {
  final IAuthRepository _authRepository;
  VerifyOtpUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse<UserModel>> call(Map<String, dynamic> params) => _authRepository.verifyOTP(params);
}
