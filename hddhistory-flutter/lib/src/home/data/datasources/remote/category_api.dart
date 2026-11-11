part of '../../../home.dart';

@lazySingleton
@RestApi()
abstract class CategoryApi {
  @factoryMethod
  factory CategoryApi(@Named(DIKey.appDio) Dio dio) = _CategoryApi;

  @GET(AppEndpoint.categories)
  Future<BaseResponse<BasePageBreak<CategoryModel>>> getAllCategories(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.categoriesById)
  Future<BaseResponse<CategoryModel>> getCategory(@Path('id') String id);
}
