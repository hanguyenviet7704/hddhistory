part of '../../../home.dart';

@lazySingleton
@RestApi()
abstract class SkillsetApi {
  @factoryMethod
  factory SkillsetApi(@Named(DIKey.appDio) Dio dio) = _SkillsetApi;

  @GET(AppEndpoint.skillsets)
  Future<BaseResponse<BasePageBreak<SkillsetModel>>> getAllSkillsets(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.skillsetsById)
  Future<BaseResponse<SkillsetModel>> getSkillset(@Path('id') String id);
}
