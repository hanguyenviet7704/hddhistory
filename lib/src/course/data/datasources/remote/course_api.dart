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

  @GET(AppEndpoint.coursesSearchHistory)
  Future<BaseResponse<List<SearchHistoryModel>>> getSearchHistory();

  @POST(AppEndpoint.coursesSearchHistory)
  Future<void> saveSearchQuery(@Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.coursesSearchHistory)
  Future<void> clearSearchHistory();

  @GET(AppEndpoint.coursesRecentlyViewed)
  Future<BaseResponse<List<CourseModel>>> getRecentlyViewedCourses();

  @POST(AppEndpoint.coursesRecentlyViewed)
  Future<void> recordCourseView(@Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.coursesRecentlyViewed)
  Future<void> clearRecentlyViewed();

  @GET(AppEndpoint.coursesExplore)
  Future<BaseResponse<ExploreResponseModel>> getExploreSections(@Query('seed') int seed);
}
