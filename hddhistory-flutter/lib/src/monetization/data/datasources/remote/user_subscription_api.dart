part of '../../../monetization.dart';

@lazySingleton
@RestApi()
abstract class UserSubscriptionApi {
  @factoryMethod
  factory UserSubscriptionApi(@Named(DIKey.appDio) Dio dio) = _UserSubscriptionApi;

  @GET(AppEndpoint.userIapSubscriptions)
  Future<BaseResponse<IapSubscriptionModel>> getUserIapSubscriptions(@Path('userId') String userId);
}
