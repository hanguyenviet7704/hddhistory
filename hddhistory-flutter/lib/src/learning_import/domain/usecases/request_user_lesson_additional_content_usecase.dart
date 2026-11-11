part of '../../learning_import.dart';

/// "I finished this and I want more of it", recorded against one generated
/// lesson.
///
/// A wish, not a job: nothing is generated, no import ticket is spent. It is the
/// same signal the catalogue collects when a level runs out of content — the only
/// honest thing to record when the answer is "more is being written".
@lazySingleton
class RequestUserLessonAdditionalContentUseCase implements BaseUseCase<String, Unit> {
  final ILearningImportRepository _repository;

  RequestUserLessonAdditionalContentUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(String id) =>
      _repository.requestAdditionalContent(id);
}
