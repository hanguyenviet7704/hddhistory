part of '../../spaced_review.dart';

@LazySingleton(as: ISpacedReviewRepository)
class SpacedReviewRepository with RestfulRequestHandlerMixin implements ISpacedReviewRepository {
  final SpacedReviewApi _api;

  SpacedReviewRepository(this._api);

  @override
  TaskEither<AppException, SpacedReviewTodayEntity> getToday() {
    return callApiWithTransform<SpacedReviewTodayModel, SpacedReviewTodayEntity>(
      apiCall: () => _api.getToday(),
      transform: (model) => model.toEntity(),
      defaultValue: const SpacedReviewTodayEntity(),
      // A Home card that fails to load just stays hidden — no toast.
      enableErrorMessages: false,
    );
  }

  @override
  TaskEither<AppException, Unit> submitAnswers(List<SpacedReviewResultEntity> results) {
    return callApiCustom<void>(
      apiCall: () => _api.submitAnswers({
        'results': [
          for (final result in results) {'keypointId': result.keypointId, 'correct': result.correct},
        ],
      }),
      enableErrorMessages: false,
    ).map((_) => unit);
  }
}
