part of '../usecases.dart';

@lazySingleton
class ResetPasswordUsecase implements UseCaseWithParams<Map<String, dynamic>, BaseResponse> {
  final IAuthRepository _authRepository;
  ResetPasswordUsecase(this._authRepository);

  @override
  TaskEither<AppException, BaseResponse> call(Map<String, dynamic> params) => _authRepository.resetPassword(params);
}
