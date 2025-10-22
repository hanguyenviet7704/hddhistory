part of '../../auth.dart';

@lazySingleton
class ForgotPasswordUsecase implements UseCaseWithParams<Map<String, dynamic>, BaseResponse<Auth>> {
  final IAuthRepository _authRepository;
  ForgotPasswordUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse<Auth>> call(Map<String, dynamic> params) => _authRepository.forgotPassword(params);
}
