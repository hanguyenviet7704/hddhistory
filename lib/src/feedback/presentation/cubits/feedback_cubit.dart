part of '../../feedback.dart';

@lazySingleton
class FeedbackCubit extends Cubit<FeedbackState> with CubitUseCaseHandlerMixin<FeedbackState> {
  final GetUserFeedbacksUseCase _getUserFeedbacksUseCase;
  final UpdateUserFeedbackUseCase _updateUserFeedbackUseCase;

  FeedbackCubit(
    this._getUserFeedbacksUseCase,
    this._updateUserFeedbackUseCase,
  ) : super(FeedbackState.initial());

  void loadUserFeedbacks() async {
    await runUseCase<UserFeedbackEntity>(
      usecase: () => _getUserFeedbacksUseCase(),
      buildLoadingState: () => state.copyWith(status: FeedbackStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: FeedbackStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: FeedbackStatus.success,
            userFeedback: item,
          ),
        );
      },
    );
  }

  void setActiveFeedback({
    required FeedbackType type,
    required FeedbackEntry entry,
  }) {
    final complete = _getCompleteFeedback(entry);
    final incomplete = _getIncompleteFeedback(entry);
    emit(
      state.copyWith(
        activeType: type,
        activeEntry: entry,
        draftContentRating: type == FeedbackType.complete ? complete.contentRating : 0,
        draftExperienceRating: type == FeedbackType.complete ? complete.experienceRating : 0,
        draftReasons: type == FeedbackType.incomplete ? List.of(incomplete.reasons) : const [],
        draftComment: type == FeedbackType.complete ? complete.comment : incomplete.comment,
      ),
    );
  }

  void updateContentRating(int rating) {
    emit(state.copyWith(draftContentRating: rating));
  }

  void updateExperienceRating(int rating) {
    emit(state.copyWith(draftExperienceRating: rating));
  }

  void toggleReason(IncompleteFeedbackReason reason) {
    final updated = [...state.draftReasons];
    if (updated.contains(reason)) {
      updated.remove(reason);
    } else {
      updated.add(reason);
    }
    emit(state.copyWith(draftReasons: updated));
  }

  void updateComment(String comment) {
    emit(state.copyWith(draftComment: comment));
  }

  void submitFeedback() async {
    final submission = _buildSubmission();
    await runUseCase<Unit>(
      usecase: () => _updateUserFeedbackUseCase(submission),
      buildLoadingState: () => state.copyWith(status: FeedbackStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: FeedbackStatus.failure, errorMessage: error));
      },
      onSuccess: (_) {
        final updated = _applySubmissionToEntity(state.userFeedback, submission);
        emit(
          state.copyWith(
            status: FeedbackStatus.success,
            userFeedback: updated,
          ),
        );
      },
    );
  }

  UserFeedbackCompleteEntity _getCompleteFeedback(FeedbackEntry entry) {
    return entry == FeedbackEntry.roleplay ? state.userFeedback.roleplayComplete : state.userFeedback.keypointComplete;
  }

  UserFeedbackIncompleteEntity _getIncompleteFeedback(FeedbackEntry entry) {
    return entry == FeedbackEntry.roleplay ? state.userFeedback.roleplayIncomplete : state.userFeedback.keypointIncomplete;
  }

  UserFeedbackSubmissionEntity _buildSubmission() {
    final complete = _getCompleteFeedback(state.activeEntry);
    final incomplete = _getIncompleteFeedback(state.activeEntry);
    final courseId = state.activeType == FeedbackType.complete ? complete.courseId : incomplete.courseId;
    final lessonId = state.activeType == FeedbackType.complete ? complete.lessonId : incomplete.lessonId;
    final keypointId = state.activeType == FeedbackType.complete ? complete.keypointId : incomplete.keypointId;

    return UserFeedbackSubmissionEntity(
      userId: state.userFeedback.userId,
      courseId: courseId,
      lessonId: lessonId,
      keypointId: keypointId,
      type: state.activeType,
      entry: state.activeEntry,
      contentRating: state.activeType == FeedbackType.complete ? state.draftContentRating : 0,
      experienceRating: state.activeType == FeedbackType.complete ? state.draftExperienceRating : 0,
      reasons: state.activeType == FeedbackType.incomplete ? state.draftReasons : const [],
      comment: state.draftComment,
    );
  }

  UserFeedbackEntity _applySubmissionToEntity(
    UserFeedbackEntity entity,
    UserFeedbackSubmissionEntity submission,
  ) {
    final now = DateTime.now();
    final userId = submission.userId.isNotEmpty ? submission.userId : entity.userId;
    if (submission.entry == FeedbackEntry.roleplay) {
      if (submission.type == FeedbackType.complete) {
        return entity.copyWith(
          userId: userId,
          roleplayComplete: entity.roleplayComplete.copyWith(
            courseId: submission.courseId,
            lessonId: submission.lessonId,
            keypointId: submission.keypointId,
            contentRating: submission.contentRating,
            experienceRating: submission.experienceRating,
            comment: submission.comment,
            submittedAt: now,
          ),
        );
      }

      return entity.copyWith(
        userId: userId,
        roleplayIncomplete: entity.roleplayIncomplete.copyWith(
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
      return entity.copyWith(
        userId: userId,
        keypointComplete: entity.keypointComplete.copyWith(
          courseId: submission.courseId,
          lessonId: submission.lessonId,
          keypointId: submission.keypointId,
          contentRating: submission.contentRating,
          experienceRating: submission.experienceRating,
          comment: submission.comment,
          submittedAt: now,
        ),
      );
    }

    return entity.copyWith(
      userId: userId,
      keypointIncomplete: entity.keypointIncomplete.copyWith(
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
