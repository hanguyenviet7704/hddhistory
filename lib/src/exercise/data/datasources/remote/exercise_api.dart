part of '../../../exercise.dart';

@lazySingleton
@RestApi()
abstract class ExerciseApi {
  @factoryMethod
  factory ExerciseApi(@Named(DIKey.appDio) Dio dio) = _ExerciseApi;

  @GET('/exercises')
  Future<BaseResponse<BasePageBreak<ExerciseModel>>> getAllExercises(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/exercises'}/{id}')
  Future<BaseResponse<ExerciseModel>> getExercise(@Path('id') String id);

  @POST('/exercises')
  Future<BaseResponse<ExerciseModel>> createExercise(@Body() Map<String, dynamic> body);

  @PUT('${'/exercises'}/{id}')
  Future<BaseResponse<ExerciseModel>> updateExercise(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/exercises'}/{id}')
  Future<BaseResponse<void>> deleteExercise(@Path('id') String id);
}
