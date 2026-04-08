part of '../../video_lesson.dart';

@LazySingleton(as: IVideoLessonRepository)
class VideoLessonRepository with RestfulRequestHandlerMixin implements IVideoLessonRepository {
  final VideoLessonApi _api;
  final VideoLessonLocalDataSource _localDataSource;

  VideoLessonRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, BasePageBreak<UserVideoLessonNoteEntity>> getAllUserVideoLessonNotes(
    PageBreakRequest<VideoLessonNoteFilterEntity> request,
  ) {
    final filter = request.filter ?? const VideoLessonNoteFilterEntity();
    return callApiPageBreak<UserVideoLessonNoteModel, UserVideoLessonNoteEntity>(
      apiCall: () => _api.getAllUserVideoLessonNotes(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async => await _localDataSource.cacheUserVideoLessonNotes(filter, pageData.items),
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUserVideoLessonNotes(filter);
        if (cachedModels.isNotEmpty) {
          return BasePageBreak<UserVideoLessonNoteEntity>(
            currentPage: 1,
            totalPages: 1,
            itemsPerPage: cachedModels.length,
            items: cachedModels.map((model) => model.toEntity()).toList(),
          );
        }
        return null;
      },
    );
  }

  @override
  TaskEither<AppException, LearningItemEntity> getLearningItem(String id) {
    return callApiWithTransform<LearningItemModel, LearningItemEntity>(
      apiCall: () => _api.getLearningItem(id),
      transform: (model) => model.toEntity(),
      defaultValue: LearningItemEntity(),
    );
  }

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> createUserVideoLessonNote(
    UserVideoLessonNoteEntity entity,
  ) {
    return callApiWithTransform<UserVideoLessonNoteModel, UserVideoLessonNoteEntity>(
      apiCall: () => _api.createUserVideoLessonNote(_noteEntityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserVideoLessonNote(data ?? UserVideoLessonNoteModel()),
      defaultValue: UserVideoLessonNoteEntity(),
    );
  }

  @override
  TaskEither<AppException, UserVideoLessonNoteEntity> updateUserVideoLessonNote(
    UserVideoLessonNoteEntity entity,
  ) {
    return callApiWithTransform<UserVideoLessonNoteModel, UserVideoLessonNoteEntity>(
      apiCall: () => _api.updateUserVideoLessonNote(entity.id, _noteEntityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserVideoLessonNote(data ?? UserVideoLessonNoteModel()),
      defaultValue: UserVideoLessonNoteEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteUserVideoLessonNote(UserVideoLessonNoteEntity entity) {
    return executeApiAction(
      apiCall: () => _api.deleteUserVideoLessonNote(entity.id),
      onSuccess: () async => await _localDataSource.deleteCachedUserVideoLessonNote(
        UserVideoLessonNoteModel(
          id: entity.id,
          userId: entity.userId,
          courseId: entity.courseId,
          nodeId: entity.nodeId,
          lessonId: entity.lessonId,
          content: entity.content,
          atSecond: entity.atSecond,
        ),
      ),
    );
  }

  Map<String, dynamic> _noteEntityToJson(UserVideoLessonNoteEntity entity) {
    return {
      'userId': entity.userId,
      'courseId': entity.courseId,
      'nodeId': entity.nodeId,
      'lessonId': entity.lessonId,
      'content': entity.content,
      if (entity.atSecond != null) 'atSecond': entity.atSecond,
    };
  }
}
