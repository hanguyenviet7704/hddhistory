part of '../../feedback.dart';

@LazySingleton(as: IFeedbackRepository)
class FeedbackRepository with RestfulRequestHandlerMixin implements IFeedbackRepository {
  final FeedbackApi _api;
  final FeedbackLocalDataSource _localDataSource;

  FeedbackRepository(
    this._api,
    this._localDataSource,
  );

  @override
  TaskEither<AppException, UserFeedbackEntity> getUserFeedbacks() {
    return callApiWithTransform<UserFeedbackModel, UserFeedbackEntity>(
      apiCall: () => _api.getUserFeedbacks(),
      transform: (model) => model.toEntity(),
      onSuccess: (data) async => await _localDataSource.cacheUserFeedback(data ?? UserFeedbackModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserFeedback();
        return cachedModel?.toEntity();
      },
      defaultValue: UserFeedbackEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> updateUserFeedback(UserFeedbackSubmissionEntity entity) {
    return executeApiAction(
      apiCall: () async {
        await _api.updateUserFeedback(_submissionToJson(entity));
      },
      onSuccess: () async {
        final cachedModel = await _localDataSource.getCachedUserFeedback();
        final updated = _applySubmission(cachedModel ?? UserFeedbackModel(userId: entity.userId), entity);
        await _localDataSource.cacheUserFeedback(updated);
      },
    );
  }

  Map<String, dynamic> _submissionToJson(UserFeedbackSubmissionEntity entity) {
    return {
      'userId': entity.userId,
      'courseId': entity.courseId,
      'lessonId': entity.lessonId,
      'keypointId': entity.keypointId,
      'type': entity.type.name,
      'entry': entity.entry.name,
      'overallRating': entity.overallRating,
      'contentRating': entity.contentRating,
      'experienceRating': entity.experienceRating,
      'reasons': entity.reasons.map((reason) => reason.apiValue).toList(),
      'comment': entity.comment,
    };
  }

  UserFeedbackModel _applySubmission(
    UserFeedbackModel model,
    UserFeedbackSubmissionEntity submission,
  ) {
    final now = DateTime.now();
    final userId = submission.userId.isNotEmpty ? submission.userId : model.userId;
    if (submission.entry == FeedbackEntry.roleplay) {
      if (submission.type == FeedbackType.complete) {
        return model.copyWith(
          userId: userId,
          roleplayComplete: model.roleplayComplete.copyWith(
            courseId: submission.courseId,
            lessonId: submission.lessonId,
            keypointId: submission.keypointId,
            overallRating: submission.overallRating,
            contentRating: submission.contentRating,
            experienceRating: submission.experienceRating,
            comment: submission.comment,
            submittedAt: now,
          ),
        );
      }

      return model.copyWith(
        userId: userId,
        roleplayIncomplete: model.roleplayIncomplete.copyWith(
          courseId: submission.courseId,
          lessonId: submission.lessonId,
          keypointId: submission.keypointId,
          reasons: submission.reasons,
          comment: submission.comment,
          submittedAt: now,
        ),
      );
    }

    if (submission.type == FeedbackType.complete) {
      return model.copyWith(
        userId: userId,
        keypointComplete: model.keypointComplete.copyWith(
          courseId: submission.courseId,
          lessonId: submission.lessonId,
          keypointId: submission.keypointId,
          overallRating: submission.overallRating,
          contentRating: submission.contentRating,
          experienceRating: submission.experienceRating,
          comment: submission.comment,
          submittedAt: now,
        ),
      );
    }

    return model.copyWith(
      userId: userId,
      keypointIncomplete: model.keypointIncomplete.copyWith(
        courseId: submission.courseId,
        lessonId: submission.lessonId,
        keypointId: submission.keypointId,
        reasons: submission.reasons,
        comment: submission.comment,
        submittedAt: now,
      ),
    );
  }
}
