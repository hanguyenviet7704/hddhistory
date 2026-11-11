part of '../../../profile.dart';

@lazySingleton
@RestApi()
abstract class ProfileApi {
  @factoryMethod
  factory ProfileApi(@Named(DIKey.appDio) Dio dio) = _ProfileApi;

  @GET(AppEndpoint.getUserProfile)
  Future<BaseResponse<UserModel>> getUserProfile(@Path('id') String id);

  @PUT(AppEndpoint.usersById)
  Future<BaseResponse<UserModel>> updateUser(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );
}
