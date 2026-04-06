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
    PageBreakRequest request,
  ) {
    return callApiPageBreak<UserVideoLessonNoteModel, UserVideoLessonNoteEntity>(
      apiCall: () => _api.getAllUserVideoLessonNotes(request),
      transform: (model) => model.toEntity(),
      onSuccess: (pageData) async => await _localDataSource.cacheUserVideoLessonNotes(pageData.items),
      onError: () async {
        final cachedModels = await _localDataSource.getCachedUserVideoLessonNotes();
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
  TaskEither<AppException, UserVideoLessonNoteEntity> createUserVideoLessonNote(
    UserVideoLessonNoteEntity entity,
  ) {
    return callApiWithTransform<UserVideoLessonNoteModel, UserVideoLessonNoteEntity>(
      apiCall: () => _api.createUserVideoLessonNote(_entityToJson(entity)),
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
      apiCall: () => _api.updateUserVideoLessonNote(entity.id, _entityToJson(entity)),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserVideoLessonNote(data ?? UserVideoLessonNoteModel()),
      defaultValue: UserVideoLessonNoteEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteUserVideoLessonNote(String id) {
    return executeApiAction(
      apiCall: () => _api.deleteUserVideoLessonNote(id),
      onSuccess: () async => await _localDataSource.deleteCachedUserVideoLessonNote(id),
    );
  }
  

  // ==================== HELPER METHODS ====================

  /// Converts UserVideoLessonNoteEntity to JSON Map for API requests
  /// Provides flexibility to customize the request body structure without affecting domain models
  /// Reusable helper to avoid duplication in create/update methods
  Map<String, dynamic> _entityToJson(UserVideoLessonNoteEntity entity) {
    return {
      'id': entity.id,
      // 'name': entity.name,
      // TODO: Add more fields as needed
    };
  }
  

  TaskEither<AppException, T> _missingDataSourceTask<T>(String operation) {
    
    return TaskEither.left(
      AppException.unexpected('$operation is not implemented. Please provide a remote or local data source.'),
    );
  }
}

