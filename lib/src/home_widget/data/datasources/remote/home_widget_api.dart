part of '../../../home_widget.dart';

@lazySingleton
@RestApi()
abstract class HomeWidgetApi {
  @factoryMethod
  factory HomeWidgetApi(@Named(DIKey.appDio) Dio dio) = _HomeWidgetApi;

  @GET(AppEndpoint.coursesUserProgressWidgetInProgress)
  Future<BaseResponse<HomeWidgetCourseModel>> getInProgressWidget();

  @GET(AppEndpoint.coursesUserProgressWidgetSuggestCourse)
  Future<BaseResponse<HomeWidgetCourseModel>> getSuggestCourseWidget();

  @GET(AppEndpoint.coursesUserProgressStreak)
  Future<BaseResponse<HomeWidgetStreakModel>> getLearningStreak();
}
