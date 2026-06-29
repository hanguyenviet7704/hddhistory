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
}
