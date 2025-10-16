part of '../../../onboard.dart';

@lazySingleton
@RestApi()
abstract class OnboardApi {
  @factoryMethod
  factory OnboardApi(@Named(DIKey.appDio) Dio dio) = _OnboardApi;

  @GET(AppEndpoint.onboardings)
  Future<List<OnboardModel>> getAllOnboards();

  @GET(AppEndpoint.onboardings)
  Future<OnboardModel> getOnboard(@Path('id') String id);

  @POST(AppEndpoint.onboardings)
  Future<OnboardModel> createOnboard(@Body() OnboardModel model);

  @PUT(AppEndpoint.onboardingsById)
  Future<OnboardModel> updateOnboard(
    @Path('id') String id,
    @Body() OnboardModel model,
  );

  @DELETE(AppEndpoint.onboardingsById)
  Future<void> deleteOnboard(@Path('id') String id);
}
