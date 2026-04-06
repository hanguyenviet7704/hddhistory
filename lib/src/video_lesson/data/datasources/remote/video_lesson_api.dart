part of '../../../video_lesson.dart';

@lazySingleton
@RestApi()
abstract class VideoLessonApi {
  @factoryMethod
  factory VideoLessonApi(@Named(DIKey.appDio) Dio dio) = _VideoLessonApi;

  @GET('/video_lessons')
  Future<BaseResponse<BasePageBreak<UserVideoLessonNoteModel>>> getAllUserVideoLessonNotes(
    @Queries() PageBreakRequest request,
  );

  @GET('${'/video_lessons'}/{id}')
  Future<BaseResponse<UserVideoLessonNoteModel>> getUserVideoLessonNote(@Path('id') String id);

  @POST('/video_lessons')
  Future<BaseResponse<UserVideoLessonNoteModel>> createUserVideoLessonNote(@Body() Map<String, dynamic> body);

  @PUT('${'/video_lessons'}/{id}')
  Future<BaseResponse<UserVideoLessonNoteModel>> updateUserVideoLessonNote(
    @Path('id') String id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('${'/video_lessons'}/{id}')
  Future<BaseResponse<void>> deleteUserVideoLessonNote(@Path('id') String id);
}

