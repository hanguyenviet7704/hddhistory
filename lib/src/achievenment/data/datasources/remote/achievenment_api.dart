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

  @POST('/achievenments')
  Future<BaseResponse<AchievenmentResponseModel>> createAchievenmentResponse(@Body() Map<String, dynamic> body);

  @PUT('${'/achievenments'}/{id}')
  Future<BaseResponse<AchievenmentResponseModel>> updateAchievenmentResponse(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/achievenments'}/{id}')
  Future<BaseResponse<void>> deleteAchievenmentResponse(@Path('id') String id);
}

