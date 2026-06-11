part of '../../../home_widget.dart';

@lazySingleton
@RestApi()
abstract class HomeWidgetApi {
  @factoryMethod
  factory HomeWidgetApi(@Named(DIKey.appDio) Dio dio) = _HomeWidgetApi;

  @GET('/api/v1/courses-user-progress/widget/in-progress')
  Future<BaseResponse<HomeWidgetCourseModel>> getInProgressWidget();

  @GET('/api/v1/courses-user-progress/widget/suggest-course')
  Future<BaseResponse<HomeWidgetCourseModel>> getSuggestCourseWidget();

  @GET('/api/v1/courses-user-progress/streak')
  Future<BaseResponse<HomeWidgetStreakModel>> getLearningStreak();
}
