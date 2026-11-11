part of '../../../progress.dart';

@lazySingleton
@RestApi()
abstract class ContentRequestApi {
  @factoryMethod
  factory ContentRequestApi(@Named(DIKey.appDio) Dio dio) = _ContentRequestApi;

  @PUT(AppEndpoint.coursesUserProgressCompletedLevelAdditionalContentRequest)
  Future<BaseResponse<UserProgressModel>> createCompletedLevelAdditionalContentRequest(@Body() Map<String, dynamic> body);
}
