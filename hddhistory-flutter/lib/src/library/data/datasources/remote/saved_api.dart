part of '../../../library.dart';

@lazySingleton
@RestApi()
abstract class SavedApi {
  @factoryMethod
  factory SavedApi(@Named(DIKey.appDio) Dio dio) = _SavedApi;

  @GET(AppEndpoint.savedCourses)
  Future<BaseResponse<BasePageBreak<CourseModel>>> getSavedCourses(
    @Query('page') int page,
    @Query('take') int take,
    @Query('status') String status,
  );

  @GET(AppEndpoint.savedCourseIds)
  Future<BaseResponseList<String>> getSavedCourseIds();

  @POST(AppEndpoint.savedCourses)
  Future<void> saveCourse(@Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.savedCourseById)
  Future<void> unsaveCourse(@Path('courseId') String courseId);

  @GET(AppEndpoint.savedCards)
  Future<BaseResponse<BasePageBreak<SavedCardModel>>> getSavedCards(
    @Query('page') int page,
    @Query('take') int take,
  );

  @GET(AppEndpoint.savedCardIds)
  Future<BaseResponseList<String>> getSavedCardIds();

  @POST(AppEndpoint.savedCards)
  Future<void> saveCard(@Body() Map<String, dynamic> body);

  @DELETE(AppEndpoint.savedCardById)
  Future<void> unsaveCard(@Path('keypointId') String keypointId);
}
