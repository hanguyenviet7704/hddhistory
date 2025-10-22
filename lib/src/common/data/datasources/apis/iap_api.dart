part of 'apis.dart';

@RestApi()
@lazySingleton
abstract class IAPApi {
  @factoryMethod
  factory IAPApi(@Named(DIKey.appDio) Dio dio) = _IAPApi;

  @POST(AppEndpoint.packages)
  Future<BaseResponseList<IapProduct>> getPackages();

  @POST(AppEndpoint.purchase)
  Future<BaseResponse<IapVerify>> purchase(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.restore)
  Future<BaseResponse<IapVerify>> restore(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyIos)
  Future<BaseResponse<IapVerify>> verifyIos(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyIosV111)
  Future<BaseResponse<IapVerify>> verifyIosV111(@Body() Map<String, dynamic> params);

  @POST(AppEndpoint.verifyAndroid)
  Future<BaseResponse<IapVerify>> verifyAndroid(@Body() Map<String, dynamic> params);
}
