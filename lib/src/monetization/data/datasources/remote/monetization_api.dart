part of '../../../monetization.dart';

@lazySingleton
@RestApi()
abstract class MonetizationApi {
  @factoryMethod
  factory MonetizationApi(@Named(DIKey.appDio) Dio dio) = _MonetizationApi;

  @GET(AppEndpoint.packages)
  Future<BaseResponse<BasePageBreak<IapProductModel>>> getPackages(@Queries() PageBreakRequest params);

  @POST(AppEndpoint.verify)
  Future<BaseResponse<IapVerifyModel>> verify(@Body() Map<String, dynamic> params);
}
