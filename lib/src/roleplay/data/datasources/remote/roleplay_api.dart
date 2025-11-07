part of '../../../roleplay.dart';

@lazySingleton
@RestApi()
abstract class RoleplayApi {
  @factoryMethod
  factory RoleplayApi(@Named(DIKey.appDio) Dio dio) = _RoleplayApi;

  @GET('/roleplays')
  Future<BaseResponse<BasePageBreak<SectionModel>>> getAllSections(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/roleplays'}/{id}')
  Future<BaseResponse<SectionModel>> getSection(@Path('id') String id);

  @POST('/roleplays')
  Future<BaseResponse<SectionModel>> createSection(@Body() Map<String, dynamic> body);

  @PUT('${'/roleplays'}/{id}')
  Future<BaseResponse<SectionModel>> updateSection(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/roleplays'}/{id}')
  Future<BaseResponse<void>> deleteSection(@Path('id') String id);
}
