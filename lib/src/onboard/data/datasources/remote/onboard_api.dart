part of '../../../onboard.dart';

@lazySingleton
@RestApi()
abstract class OnboardApi {
  @factoryMethod
  factory OnboardApi(@Named(DIKey.appDio) Dio dio) = _OnboardApi;

  @GET(AppEndpoint.onboardings)
  Future<BaseResponse<BasePageBreak<OnboardModel>>> getAllOnboards(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.onboardingsById)
  Future<BaseResponse<OnboardModel>> getOnboard(@Path('id') String id);

  @POST(AppEndpoint.onboardings)
  Future<BaseResponse<OnboardModel>> createOnboard(@Body() OnboardModel model);

  @PUT(AppEndpoint.onboardingsById)
  Future<BaseResponse<OnboardModel>> updateOnboard(
    @Path('id') String id,
    @Body() OnboardModel model,
  );

  @DELETE(AppEndpoint.onboardingsById)
  Future<BaseResponse<void>> deleteOnboard(@Path('id') String id);
}
