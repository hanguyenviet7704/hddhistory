part of '../../spaced_review.dart';

@lazySingleton
class GetSpacedReviewTodayUseCase implements BaseUseCase<Unit, SpacedReviewTodayEntity> {
  final ISpacedReviewRepository _repository;

  GetSpacedReviewTodayUseCase(this._repository);

  @override
  TaskEither<AppException, SpacedReviewTodayEntity> call(Unit _) {
    return _repository.getToday();
  }
}
