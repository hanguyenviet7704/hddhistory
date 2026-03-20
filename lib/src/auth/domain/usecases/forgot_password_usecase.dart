part of '../../auth.dart';

@lazySingleton
class ForgotPasswordUsecase implements BaseUseCase<Map<String, dynamic>, BaseResponse<AuthEntity>> {
  // ignore: unused_field
  final IAuthRepository _authRepository;
  ForgotPasswordUsecase(this._authRepository);

  @override
  // TaskEither<AppException, BaseResponse<AuthEntity>> call(Map<String, dynamic> params) => _authRepository.forgotPassword(params);
  TaskEither<AppException, BaseResponse<AuthEntity>> call(Map<String, dynamic> params) => TaskEither.left(AppException.unexpected('Not implemented'));
}
