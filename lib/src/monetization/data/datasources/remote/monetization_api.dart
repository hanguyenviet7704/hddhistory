part of '../../../monetization.dart';

@lazySingleton
@RestApi()
abstract class MonetizationApi {
  @factoryMethod
  factory MonetizationApi(@Named(DIKey.appDio) Dio dio) = _MonetizationApi;

  @POST(AppEndpoint.packages)
  Future<BaseResponseList<IapProductModel>> getPackages();

  @POST(AppEndpoint.purchase)
  Future<BaseResponse<IapVerifyModel>> purchase(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.restore)
  Future<BaseResponse<IapVerifyModel>> restore(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyIos)
  Future<BaseResponse<IapVerifyModel>> verifyIos(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyIosV111)
  Future<BaseResponse<IapVerifyModel>> verifyIosV111(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyAndroid)
  Future<BaseResponse<IapVerifyModel>> verifyAndroid(@Body() Map<String, dynamic> params);
}

