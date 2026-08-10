part of '../../../learning_import.dart';

@lazySingleton
@RestApi()
abstract class LearningImportApi {
  @factoryMethod
  factory LearningImportApi(@Named(DIKey.appDio) Dio dio) = _LearningImportApi;

  /// Start a generation run. Returns immediately with a job to poll — the work
  /// itself takes minutes. For a PDF the body carries the R2 object key from
  /// [AppEndpoint.cloudflareUpload], never the file.
  @POST(AppEndpoint.learningImports)
  Future<BaseResponse<LearningImportJobModel>> createImport(
    @Body() Map<String, dynamic> body,
  );

  @GET(AppEndpoint.learningImportQuota)
  Future<BaseResponse<ImportQuotaModel>> getQuota();

  @GET(AppEndpoint.learningImportById)
  Future<BaseResponse<LearningImportJobModel>> getJob(
    @Path('jobId') String jobId,
  );

  @GET(AppEndpoint.userLessons)
  Future<BaseResponse<BasePageBreak<UserLessonModel>>> getUserLessons(
    @Query('page') int page,
    @Query('take') int take,
  );

  @GET(AppEndpoint.userLessonById)
  Future<BaseResponse<UserLessonModel>> getUserLesson(@Path('id') String id);

  @PATCH(AppEndpoint.userLessonProgress)
  Future<BaseResponse<dynamic>> updateProgress(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(AppEndpoint.userLessonById)
  Future<void> deleteUserLesson(@Path('id') String id);
}
