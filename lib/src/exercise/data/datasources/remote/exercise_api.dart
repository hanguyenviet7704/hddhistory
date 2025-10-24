part of '../../../exercise.dart';

@lazySingleton
@RestApi()
abstract class ExerciseApi {
  @factoryMethod
  factory ExerciseApi(@Named(DIKey.appDio) Dio dio) = _ExerciseApi;

  @GET('/exercises')
  Future<BaseResponse<BasePageBreak<LearningItemModel>>> getAllLearningItems(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/exercises'}/{id}')
  Future<BaseResponse<LearningItemModel>> getLearningItem(@Path('id') String id);

  @POST('/exercises')
  Future<BaseResponse<LearningItemModel>> createLearningItem(@Body() Map<String, dynamic> body);

  @PUT('${'/exercises'}/{id}')
  Future<BaseResponse<LearningItemModel>> updateLearningItem(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/exercises'}/{id}')
  Future<BaseResponse<void>> deleteLearningItem(@Path('id') String id);
}
