part of '../../auth.dart';

@lazySingleton
class ResetPasswordUsecase implements UseCaseWithParams<Map<String, dynamic>, Unit> {
  final IAuthRepository _authRepository;
  ResetPasswordUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(Map<String, dynamic> params) => _authRepository.resetPassword(params);
}
