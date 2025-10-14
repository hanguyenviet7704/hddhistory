part of '../../../onboard.dart';

@lazySingleton
@RestApi()
abstract class OnboardApi {
  @factoryMethod
  factory OnboardApi(@Named(DIKey.appDio) Dio dio) = _OnboardApi;

  @GET('/onboards')
  Future<List<OnboardModel>> getAllOnboards();

  @GET('${'/onboards'}/{id}')
  Future<OnboardModel> getOnboard(@Path('id') String id);

  @POST('/onboards')
  Future<OnboardModel> createOnboard(@Body() OnboardModel model);

  @PUT('${'/onboards'}/{id}')
  Future<OnboardModel> updateOnboard(
    @Path('id') String id,
    @Body() OnboardModel model,
  );

  @DELETE('${'/onboards'}/{id}')
  Future<void> deleteOnboard(@Path('id') String id);
}
