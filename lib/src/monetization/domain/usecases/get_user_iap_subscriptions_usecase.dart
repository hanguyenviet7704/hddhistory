part of '../../monetization.dart';

@lazySingleton
class GetUserIapSubscriptionsUseCase implements UseCaseWithParams<String, IapSubscriptionEntity> {
  final IUserSubscriptionRepository _repository;

  GetUserIapSubscriptionsUseCase(this._repository);

  @override
  TaskEither<AppException, IapSubscriptionEntity> call(String params) {
    return _repository.getUserIapSubscriptions(params);
  }
}
