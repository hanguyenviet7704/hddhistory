part of '../../feedback.dart';

@LazySingleton(as: IFeedbackRepository)
class FeedbackRepository
    with RestfulRequestHandlerMixin
    implements IFeedbackRepository {
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
      onSuccess: (data) async =>
          await _localDataSource.cacheUserFeedback(data ?? UserFeedbackModel()),
      onError: () async {
        final cachedModel = await _localDataSource.getCachedUserFeedback();
        return cachedModel?.toEntity();
      },
      defaultValue: UserFeedbackEntity(),
    );
  }

  @override
  TaskEither<AppException, Unit> updateUserFeedback(UserFeedbackEntity entity) {
    return executeApiAction(
      apiCall: () async {
        await _api.updateUserFeedback(_entityToJson(entity));
      },
      onSuccess: () async =>
          await _localDataSource.cacheUserFeedback(_entityToModel(entity)),
    );
  }

  Map<String, dynamic> _entityToJson(UserFeedbackEntity entity) {
    return {
      'userId': entity.userId,
      'roleplayComplete': _completeEntityToJson(entity.roleplayComplete),
      'roleplayIncomplete': _incompleteEntityToJson(entity.roleplayIncomplete),
      'keypointComplete': _completeEntityToJson(entity.keypointComplete),
      'keypointIncomplete': _incompleteEntityToJson(entity.keypointIncomplete),
    };
  }

  Map<String, dynamic> _completeEntityToJson(UserFeedbackCompleteEntity e) {
    return {
      'courseId': e.courseId,
      'courseTitle': e.courseTitle.toJson(),
      'lessonId': e.lessonId,
      'lessonTitle': e.lessonTitle.toJson(),
      'keypointId': e.keypointId,
      'keypointTitle': e.keypointTitle.toJson(),
      'contentRating': e.contentRating,
      'experienceRating': e.experienceRating,
      'comment': e.comment,
      'submittedAt': e.submittedAt?.toIso8601String(),
    };
  }

  Map<String, dynamic> _incompleteEntityToJson(UserFeedbackIncompleteEntity e) {
    return {
      'courseId': e.courseId,
      'courseTitle': e.courseTitle.toJson(),
      'lessonId': e.lessonId,
      'lessonTitle': e.lessonTitle.toJson(),
      'keypointId': e.keypointId,
      'keypointTitle': e.keypointTitle.toJson(),
      'reasons': e.reasons.map((r) => r.name).toList(),
      'comment': e.comment,
      'submittedAt': e.submittedAt?.toIso8601String(),
    };
  }

  UserFeedbackModel _entityToModel(UserFeedbackEntity entity) {
    return UserFeedbackModel(
      userId: entity.userId,
      roleplayComplete: UserFeedbackCompleteModel(
        courseId: entity.roleplayComplete.courseId,
        courseTitle: entity.roleplayComplete.courseTitle,
        lessonId: entity.roleplayComplete.lessonId,
        lessonTitle: entity.roleplayComplete.lessonTitle,
        keypointId: entity.roleplayComplete.keypointId,
        keypointTitle: entity.roleplayComplete.keypointTitle,
        contentRating: entity.roleplayComplete.contentRating,
        experienceRating: entity.roleplayComplete.experienceRating,
        comment: entity.roleplayComplete.comment,
        submittedAt: entity.roleplayComplete.submittedAt,
      ),
      roleplayIncomplete: UserFeedbackIncompleteModel(
        courseId: entity.roleplayIncomplete.courseId,
        courseTitle: entity.roleplayIncomplete.courseTitle,
        lessonId: entity.roleplayIncomplete.lessonId,
        lessonTitle: entity.roleplayIncomplete.lessonTitle,
        keypointId: entity.roleplayIncomplete.keypointId,
        keypointTitle: entity.roleplayIncomplete.keypointTitle,
        reasons: entity.roleplayIncomplete.reasons,
        comment: entity.roleplayIncomplete.comment,
        submittedAt: entity.roleplayIncomplete.submittedAt,
      ),
      keypointComplete: UserFeedbackCompleteModel(
        courseId: entity.keypointComplete.courseId,
        courseTitle: entity.keypointComplete.courseTitle,
        lessonId: entity.keypointComplete.lessonId,
        lessonTitle: entity.keypointComplete.lessonTitle,
        keypointId: entity.keypointComplete.keypointId,
        keypointTitle: entity.keypointComplete.keypointTitle,
        contentRating: entity.keypointComplete.contentRating,
        experienceRating: entity.keypointComplete.experienceRating,
        comment: entity.keypointComplete.comment,
        submittedAt: entity.keypointComplete.submittedAt,
      ),
      keypointIncomplete: UserFeedbackIncompleteModel(
        courseId: entity.keypointIncomplete.courseId,
        courseTitle: entity.keypointIncomplete.courseTitle,
        lessonId: entity.keypointIncomplete.lessonId,
        lessonTitle: entity.keypointIncomplete.lessonTitle,
        keypointId: entity.keypointIncomplete.keypointId,
        keypointTitle: entity.keypointIncomplete.keypointTitle,
        reasons: entity.keypointIncomplete.reasons,
        comment: entity.keypointIncomplete.comment,
        submittedAt: entity.keypointIncomplete.submittedAt,
      ),
    );
  }
}

