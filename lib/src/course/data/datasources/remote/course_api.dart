part of '../../../course.dart';

@lazySingleton
@RestApi()
abstract class CourseApi {
  @factoryMethod
  factory CourseApi(@Named(DIKey.appDio) Dio dio) = _CourseApi;

  @GET(AppEndpoint.courses)
  Future<BaseResponse<BasePageBreak<CourseModel>>> getAllCourses(
    @Queries() PageBreakRequest<CourseFilterRequest> request,
  );

  @GET(AppEndpoint.coursesById)
  Future<BaseResponse<CourseModel>> getCourse(@Path('id') String id);

  @GET(AppEndpoint.coursesRoadmap)
  Future<BaseResponse<RoadmapModel>> getRoadmap(@Path('id') String id);
}
