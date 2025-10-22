part of 'apis.dart';

@RestApi()
@lazySingleton
abstract class ProfileApi {
  @factoryMethod
  factory ProfileApi(@Named(DIKey.appDio) Dio dio) = _ProfileApi;

  @POST(AppEndpoint.changeProfileId)
  Future<BaseResponse<ChangeUserProfileIdModel>> changeProfileId(@Body() Map<String, dynamic> data);
}
