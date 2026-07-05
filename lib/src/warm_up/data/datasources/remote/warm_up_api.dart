part of '../../../warm_up.dart';

@lazySingleton
@RestApi()
abstract class WarmUpApi {
  @factoryMethod
  factory WarmUpApi(@Named(DIKey.appDio) Dio dio) = _WarmUpApi;

  @GET(AppEndpoint.warmUpForCourse)
  Future<BaseResponse<WarmUpForCourseModel>> getWarmUpForCourse(@Path('courseId') String courseId);
}
