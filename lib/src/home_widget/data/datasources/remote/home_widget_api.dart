part of '../../../home_widget.dart';

@lazySingleton
@RestApi()
abstract class HomeWidgetApi {
  @factoryMethod
  factory HomeWidgetApi(@Named(DIKey.appDio) Dio dio) = _HomeWidgetApi;

  @GET('/home_widgets')
  Future<BaseResponse<BasePageBreak<HomeWidgetModel>>> getAllHomeWidgets(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/home_widgets'}/{id}')
  Future<BaseResponse<HomeWidgetModel>> getHomeWidget(@Path('id') String id);

  @POST('/home_widgets')
  Future<BaseResponse<HomeWidgetModel>> createHomeWidget(@Body() Map<String, dynamic> body);

  @PUT('${'/home_widgets'}/{id}')
  Future<BaseResponse<HomeWidgetModel>> updateHomeWidget(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/home_widgets'}/{id}')
  Future<BaseResponse<void>> deleteHomeWidget(@Path('id') String id);
}

