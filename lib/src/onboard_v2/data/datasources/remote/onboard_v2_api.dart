part of '../../../onboard_v2.dart';

@lazySingleton
@RestApi()
abstract class OnboardV2Api {
  @factoryMethod
  factory OnboardV2Api(@Named(DIKey.appDio) Dio dio) = _OnboardV2Api;

  @GET('/onboard_v2s')
  Future<BaseResponse<BasePageBreak<OnboardV2Model>>> getAllOnboardV2s(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/onboard_v2s'}/{id}')
  Future<BaseResponse<OnboardV2Model>> getOnboardV2(@Path('id') String id);

  @POST('/onboard_v2s')
  Future<BaseResponse<OnboardV2Model>> createOnboardV2(@Body() Map<String, dynamic> body);

  @PUT('${'/onboard_v2s'}/{id}')
  Future<BaseResponse<OnboardV2Model>> updateOnboardV2(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/onboard_v2s'}/{id}')
  Future<BaseResponse<void>> deleteOnboardV2(@Path('id') String id);
}
