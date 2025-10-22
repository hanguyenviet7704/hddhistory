part of '../../auth.dart';

@lazySingleton
class ForgotPasswordUsecase implements UseCaseWithParams<Map<String, dynamic>, BaseResponse<AuthEntity>> {
  final IAuthRepository _authRepository;
  ForgotPasswordUsecase(this._authRepository);

  @override
  // TaskEither<AppException, BaseResponse<AuthEntity>> call(Map<String, dynamic> params) => _authRepository.forgotPassword(params);
  TaskEither<AppException, BaseResponse<AuthEntity>> call(Map<String, dynamic> params) => TaskEither.left(AppException.unexpected('Not implemented'));
}
