part of '../../roleplay.dart';

@lazySingleton
class SendFeedbackRoleplayUseCase implements UseCaseWithParams<Map<String, dynamic>, RoleplayFeedbackEntity> {
  final IRoleplayRepository _repository;

  SendFeedbackRoleplayUseCase(this._repository);

  @override
  TaskEither<AppException, RoleplayFeedbackEntity> call(Map<String, dynamic> params) {
    return _repository.sendFeedbackRoleplay(params);
  }
}
