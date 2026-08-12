part of '../../../home.dart';

@lazySingleton
@RestApi()
abstract class HomeApi {
  @factoryMethod
  factory HomeApi(@Named(DIKey.appDio) Dio dio) = _HomeApi;

  @GET(AppEndpoint.coursesQuotesRandom)
  Future<BaseResponse<QuoteModel>> getRandomQuote();

  @GET(AppEndpoint.coursesUserProgressSuggestCourses)
  Future<BaseResponse<List<SuggestedCourseModel>>> getSuggestCourses(
    @Query('limit') int limit,
  );

  @GET(AppEndpoint.homeBanner)
  Future<BaseResponse<HomeBannerModel>> getHomeBanner();

  @GET(AppEndpoint.homePopup)
  Future<BaseResponse<HomePopupModel>> getHomePopup();

  @POST(AppEndpoint.homePopupClick)
  Future<BaseResponse<HomePopupClickResultModel>> markHomePopupClicked(
    @Body() Map<String, dynamic> body,
  );
}
