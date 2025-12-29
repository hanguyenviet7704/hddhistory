part of '../../../achievenment.dart';

@lazySingleton
@RestApi()
abstract class AchievenmentApi {
  @factoryMethod
  factory AchievenmentApi(@Named(DIKey.appDio) Dio dio) = _AchievenmentApi;

  @GET('/achievenments')
  Future<BaseResponse<BasePageBreak<AchievenmentResponseModel>>> getAllAchievenmentResponses(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/achievenments'}/{id}')
  Future<BaseResponse<AchievenmentResponseModel>> getAchievenmentResponse(@Path('id') String id);
}

