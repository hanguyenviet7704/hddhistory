part of '../../library.dart';

@LazySingleton(as: ISavedRepository)
class SavedRepository with RestfulRequestHandlerMixin implements ISavedRepository {
  final SavedApi _api;

  SavedRepository(this._api);

  @override
  TaskEither<AppException, BasePageBreak<CourseEntity>> getSavedCourses({
    required int page,
    required int take,
    required SavedCourseFilter filter,
  }) {
    return callApiPageBreak<CourseModel, CourseEntity>(
      apiCall: () => _api.getSavedCourses(page, take, filter.query),
      transform: (model) => model.toEntity(),
      // The Saved screen draws its own error and empty branches.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, List<String>> getSavedCourseIds() {
    return callApiCustom<List<String>>(
      apiCall: () async => (await _api.getSavedCourseIds()).data,
      // Silent: a dropped id read only means a bookmark draws hollow until the
      // next refresh. A toast for that would fire on every cold start with a
      // flaky connection, on screens the reader did not ask this of.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> saveCourse(String courseId) {
    return _fireAndForget(() => _api.saveCourse({'courseId': courseId}));
  }

  @override
  TaskEither<AppException, Unit> unsaveCourse(String courseId) {
    return _fireAndForget(() => _api.unsaveCourse(courseId));
  }

  @override
  TaskEither<AppException, BasePageBreak<SavedCardEntity>> getSavedCards({
    required int page,
    required int take,
  }) {
    return callApiPageBreak<SavedCardModel, SavedCardEntity>(
      apiCall: () => _api.getSavedCards(page, take),
      transform: (model) => model.toEntity(),
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, List<String>> getSavedCardIds() {
    return callApiCustom<List<String>>(
      apiCall: () async => (await _api.getSavedCardIds()).data,
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> saveCard(SaveCardParams params) {
    return _fireAndForget(
      () => _api.saveCard({
        'keypointId': params.keypointId,
        if (params.lessonId.isNotEmpty) 'lessonId': params.lessonId,
        if (params.courseId.isNotEmpty) 'courseId': params.courseId,
        if (params.recapText.isNotEmpty) 'recapText': params.recapText,
      }),
    );
  }

  @override
  TaskEither<AppException, Unit> unsaveCard(String keypointId) {
    return _fireAndForget(() => _api.unsaveCard(keypointId));
  }

  /// The four writes share one shape: no body to read back, and no toast.
  ///
  /// The cubit flips the bookmark optimistically and rolls it back on a Left,
  /// so the failure the reader sees is the icon returning to hollow — which
  /// says "not saved" more clearly, and more quietly, than a red banner over
  /// the card they were reading.
  TaskEither<AppException, Unit> _fireAndForget(Future<void> Function() call) {
    return TaskEither.tryCatch(
      () async {
        await call();
        return unit;
      },
      (error, stackTrace) => error is DioException ? AppException.fromDioException(error) : AppException.unexpected(error.toString()),
    );
  }
}
