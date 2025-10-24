part of '../../../exercise.dart';

@lazySingleton
@RestApi()
abstract class ExerciseApi {
  @factoryMethod
  factory ExerciseApi(@Named(DIKey.appDio) Dio dio) = _ExerciseApi;

  @GET(AppEndpoint.coursesLearningItems)
  Future<BaseResponse<BasePageBreak<LearningItemModel>>> getAllLearningItems(
    @Queries() PageBreakRequest request,
  );

  @GET(AppEndpoint.coursesLearningItemsById)
  Future<BaseResponse<LearningItemModel>> getLearningItem(@Path('id') String id);
}
