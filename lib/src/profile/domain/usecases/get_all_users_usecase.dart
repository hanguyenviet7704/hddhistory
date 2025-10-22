part of '../../profile.dart';

@lazySingleton
class GetAllUsersUseCase implements UseCaseWithParams<PageBreakRequest, BasePageBreak<UserEntity>> {
  final IProfileRepository _repository;

  GetAllUsersUseCase(this._repository);

  @override
  TaskEither<AppException, BasePageBreak<UserEntity>> call(PageBreakRequest params) {
    return _repository.getAllUsers(params);
  }
}
