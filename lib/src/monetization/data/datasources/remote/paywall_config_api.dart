part of '../../../monetization.dart';

/// Fetches the paywall configuration blob from the backend CMS.
///
/// The response body is exactly the same JSON shape Firebase Remote Config
/// used to hold under the `paywall_config` key (see
/// [PaywallConfigEntity.fromRawConfig]), so this deliberately returns the raw
/// decoded body (`dynamic`, same pattern as `HabitApi.getHabitConfig`)
/// instead of a bespoke model — [PaywallConfigEntity.fromRawConfig] already
/// owns the lenient per-locale parsing and must not be duplicated here.
@lazySingleton
@RestApi()
abstract class PaywallConfigApi {
  @factoryMethod
  factory PaywallConfigApi(@Named(DIKey.appDio) Dio dio) = _PaywallConfigApi;

  @GET(AppEndpoint.paywallConfigMobile)
  Future<BaseResponse<dynamic>> getPaywallConfig();
}
