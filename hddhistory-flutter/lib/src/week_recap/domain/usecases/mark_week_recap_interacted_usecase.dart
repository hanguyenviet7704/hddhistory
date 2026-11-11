part of '../../week_recap.dart';

@lazySingleton
class MarkWeekRecapInteractedUseCase {
  final IWeekRecapRepository _repository;

  MarkWeekRecapInteractedUseCase(this._repository);

  /// [viewed] false is "Để sau" — it silences the popup without claiming the
  /// learner looked at their week.
  TaskEither<AppException, Unit> call({required String id, required bool viewed}) {
    return _repository.markInteracted(id: id, viewed: viewed);
  }
}
