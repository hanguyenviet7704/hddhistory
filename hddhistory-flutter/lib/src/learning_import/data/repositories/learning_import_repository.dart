part of '../../learning_import.dart';

@LazySingleton(as: ILearningImportRepository)
class LearningImportRepository
    with RestfulRequestHandlerMixin
    implements ILearningImportRepository {
  final LearningImportApi _api;

  LearningImportRepository(this._api);

  @override
  TaskEither<AppException, LearningImportJobEntity> createImport(
    CreateLearningImportParams params,
  ) {
    return callApiWithTransform<LearningImportJobModel, LearningImportJobEntity>(
      apiCall: () => _api.createImport({
        'sourceType': params.isPdf ? 'pdf' : 'youtube',
        if (params.isPdf) 'fileKey': params.fileKey,
        if (params.isPdf && params.fileName != null)
          'fileName': params.fileName,
        if (!params.isPdf) 'url': params.url,
        'outputLocale': params.outputLocale,
      }),
      transform: (model) => model.toEntity(),
      defaultValue: const LearningImportJobEntity(),
      // The only call here that keeps the base toast: a rejection at create
      // time (not premium / out of credits / one already running) is something
      // the user must see, and the server's message already says which.
    );
  }

  @override
  TaskEither<AppException, LearningImportJobEntity> getJob(String jobId) {
    return callApiWithTransform<LearningImportJobModel, LearningImportJobEntity>(
      apiCall: () => _api.getJob(jobId),
      transform: (model) => model.toEntity(),
      defaultValue: const LearningImportJobEntity(),
      // Silent: this runs every 3 seconds while the user watches the progress
      // screen. One dropped poll is invisible; a toast per dropped poll is not.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, ImportQuotaEntity> getQuota() {
    return callApiWithTransform<ImportQuotaModel, ImportQuotaEntity>(
      apiCall: () => _api.getQuota(),
      transform: (model) => model.toEntity(),
      defaultValue: const ImportQuotaEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<UserLessonEntity>> getUserLessons({
    required int page,
    required int take,
  }) {
    return callApiPageBreak<UserLessonModel, UserLessonEntity>(
      apiCall: () => _api.getUserLessons(page, take),
      transform: (model) => model.toEntity(),
      // The list screen renders its own error/empty state.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, UserLessonEntity> getUserLesson(String id) {
    return callApiWithTransform<UserLessonModel, UserLessonEntity>(
      apiCall: () => _api.getUserLesson(id),
      transform: (model) => model.toEntity(),
      defaultValue: const UserLessonEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> updateProgress(
    UpdateLessonProgressParams params,
  ) {
    return TaskEither.tryCatch(
      () async {
        await _api.updateProgress(params.lessonId, {
          'stopAtKeypointIndex': params.stopAtKeypointIndex,
          'stopAtSectionIndex': params.stopAtSectionIndex,
        });
        return unit;
      },
      // Fire-and-forget from the reader's point of view: losing a bookmark write
      // costs the user their place, not their lesson, and surfacing it as a
      // toast while they are reading would be worse than the loss.
      (error, stackTrace) => error is DioException
          ? AppException.fromDioException(error)
          : AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, Unit> requestAdditionalContent(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.requestAdditionalContent(id);
        return unit;
      },
      (error, stackTrace) => error is DioException
          ? AppException.fromDioException(error)
          : AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, Unit> deleteUserLesson(String id) {
    return TaskEither.tryCatch(
      () async {
        await _api.deleteUserLesson(id);
        return unit;
      },
      (error, stackTrace) => error is DioException
          ? AppException.fromDioException(error)
          : AppException.unexpected(error.toString()),
    );
  }
}
