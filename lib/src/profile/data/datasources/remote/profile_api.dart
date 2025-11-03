part of '../../../profile.dart';

@lazySingleton
@RestApi()
abstract class ProfileApi {
  @factoryMethod
  factory ProfileApi(@Named(DIKey.appDio) Dio dio) = _ProfileApi;

  @GET('/profiles')
  Future<BaseResponse<BasePageBreak<UserModel>>> getAllUsers(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/profiles'}/{id}')
  Future<BaseResponse<UserModel>> getUser(@Path('id') String id);

  @POST('/profiles')
  Future<BaseResponse<UserModel>> createUser(@Body() Map<String, dynamic> body);

  @PUT('${'/profiles'}/{id}')
  Future<BaseResponse<UserModel>> updateUser(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/profiles'}/{id}')
  Future<BaseResponse<void>> deleteUser(@Path('id') String id);
}
