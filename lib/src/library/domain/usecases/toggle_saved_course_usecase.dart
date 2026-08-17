part of '../../library.dart';

/// Save or unsave in one use case: the caller always knows which way the
/// bookmark is going, and two classes for one bit would only push that branch
/// up into the cubit.
@lazySingleton
class ToggleSavedCourseUseCase {
  final ISavedRepository _repository;

  ToggleSavedCourseUseCase(this._repository);

  TaskEither<AppException, Unit> call({
    required String courseId,
    required bool save,
  }) => save ? _repository.saveCourse(courseId) : _repository.unsaveCourse(courseId);
}
