part of '../../monetization.dart';

abstract class IUserSubscriptionRepository {
  TaskEither<AppException, IapSubscriptionEntity> getUserIapSubscriptions(String userId);
}
