part of '../../../roadmap.dart';

@lazySingleton
@RestApi()
abstract class RoadmapApi {
  @factoryMethod
  factory RoadmapApi(@Named(DIKey.appDio) Dio dio) = _RoadmapApi;

  @GET('/roadmaps')
  Future<BaseResponse<BasePageBreak<RoadmapModel>>> getAllRoadmaps(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/roadmaps'}/{id}')
  Future<BaseResponse<RoadmapModel>> getRoadmap(@Path('id') String id);

  @POST('/roadmaps')
  Future<BaseResponse<RoadmapModel>> createRoadmap(@Body() Map<String, dynamic> body);

  @PUT('${'/roadmaps'}/{id}')
  Future<BaseResponse<RoadmapModel>> updateRoadmap(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/roadmaps'}/{id}')
  Future<BaseResponse<void>> deleteRoadmap(@Path('id') String id);
}
