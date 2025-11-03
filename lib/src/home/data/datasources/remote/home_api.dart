part of '../../../home.dart';

@lazySingleton
@RestApi()
abstract class HomeApi {
  @factoryMethod
  factory HomeApi(@Named(DIKey.appDio) Dio dio) = _HomeApi;

  @GET('/homes')
  Future<BaseResponse<BasePageBreak<SkillsetModel>>> getAllSkillsets(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/homes'}/{id}')
  Future<BaseResponse<SkillsetModel>> getSkillset(@Path('id') String id);

  @POST('/homes')
  Future<BaseResponse<SkillsetModel>> createSkillset(@Body() Map<String, dynamic> body);

  @PUT('${'/homes'}/{id}')
  Future<BaseResponse<SkillsetModel>> updateSkillset(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/homes'}/{id}')
  Future<BaseResponse<void>> deleteSkillset(@Path('id') String id);
}
