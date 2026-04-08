part of '../../../video_lesson.dart';

@lazySingleton
@RestApi()
abstract class VideoLessonApi {
  @factoryMethod
  factory VideoLessonApi(@Named(DIKey.appDio) Dio dio) = _VideoLessonApi;

  @GET(AppEndpoint.coursesUserVideoLessonsActivity)
  Future<BaseResponse<BasePageBreak<UserVideoLessonNoteModel>>> getAllUserVideoLessonNotes(
    @Queries() PageBreakRequest<VideoLessonNoteFilterEntity> request,
  );

  @GET(AppEndpoint.coursesUserVideoLessonsActivityById)
  Future<BaseResponse<UserVideoLessonNoteModel>> getUserVideoLessonNote(@Path('id') String id);

  @GET(AppEndpoint.coursesLearningItemsById)
  Future<BaseResponse<LearningItemModel>> getLearningItem(@Path('id') String id);

  @POST(AppEndpoint.coursesUserVideoLessonsActivity)
  Future<BaseResponse<UserVideoLessonNoteModel>> createUserVideoLessonNote(@Body() Map<String, dynamic> body);

  @PUT(AppEndpoint.coursesUserVideoLessonsActivityById)
  Future<BaseResponse<UserVideoLessonNoteModel>> updateUserVideoLessonNote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE(AppEndpoint.coursesUserVideoLessonsActivityById)
  Future<BaseResponse<void>> deleteUserVideoLessonNote(@Path('id') String id);
}
