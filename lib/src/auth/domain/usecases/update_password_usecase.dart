part of '../../auth.dart';

@lazySingleton
class UpdatePasswordUsecase implements UseCaseWithParams<Map<String, dynamic>, Unit> {
  final IAuthRepository _authRepository;
  UpdatePasswordUsecase(this._authRepository);

  @override
  TaskEither<AppException, Unit> call(Map<String, dynamic> params) => _authRepository.updatePassword(params);
}
