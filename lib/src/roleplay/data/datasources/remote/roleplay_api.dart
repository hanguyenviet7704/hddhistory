part of '../../../roleplay.dart';

@lazySingleton
@RestApi()
abstract class RoleplayApi {
  @factoryMethod
  factory RoleplayApi(@Named(DIKey.appDio) Dio dio) = _RoleplayApi;

  @GET(AppEndpoint.coursesLearningItems)
  Future<BaseResponse<BasePageBreak<LearningItemModel>>> getAllLearningItems(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesLearningItemsById)
  Future<BaseResponse<LearningItemModel>> getLearningItem(@Path('id') String id);
}
