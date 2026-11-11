part of '../../spaced_review.dart';

@lazySingleton
class SubmitSpacedReviewUseCase implements BaseUseCase<List<SpacedReviewResultEntity>, Unit> {
  final ISpacedReviewRepository _repository;

  SubmitSpacedReviewUseCase(this._repository);

  @override
  TaskEither<AppException, Unit> call(List<SpacedReviewResultEntity> results) {
    return _repository.submitAnswers(results);
  }
}
