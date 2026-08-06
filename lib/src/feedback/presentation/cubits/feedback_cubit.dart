part of '../../feedback.dart';

@lazySingleton
class FeedbackCubit extends HydratedCubit<FeedbackState> with CubitUseCaseHandlerMixin<FeedbackState> {
  final GetUserFeedbacksUseCase _getUserFeedbacksUseCase;
  final UpdateUserFeedbackUseCase _updateUserFeedbackUseCase;

  FeedbackCubit(
    this._getUserFeedbacksUseCase,
    this._updateUserFeedbackUseCase,
  ) : super(FeedbackState.initial());

  /// Pinned so an obfuscated release build cannot rename the key this
  /// cubit's state is stored under — see [HydrateBlocService].
  @override
  String get storagePrefix => 'FeedbackCubit';

  @override
  FeedbackState fromJson(Map<String, dynamic> json) => FeedbackState.fromJson(json);

  @override
  Map<String, dynamic> toJson(FeedbackState state) => state.toJson();

  /// Marks the "how was your lesson?" popup as used up — call this right
  /// after presenting it (submit or skip, doesn't matter) so it never shows
  /// again past the user's first lesson.
  void markFirstCompleteLessonFeedbackShown() {
    if (state.hasShownFirstCompleteLessonFeedback) return;
    emit(state.copyWith(hasShownFirstCompleteLessonFeedback: true));
  }

  void loadUserFeedbacks() async {
    await runUseCase<UserFeedbackEntity>(
      usecase: () => _getUserFeedbacksUseCase(unit),
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
    FeedbackEntry? entry,
    required String courseId,
    required String lessonId,
    required String keypointId,
  }) {
    FeedbackEntry activeEntry = entry ?? state.activeEntry;
    final complete = _getCompleteFeedback(activeEntry);
    final incomplete = _getIncompleteFeedback(activeEntry);
    emit(
      state.copyWith(
        activeType: type,
        activeEntry: activeEntry,
        activeCourseId: courseId,
        activeLessonId: lessonId,
        activeKeypointId: keypointId,
        draftOverallRating: type == FeedbackType.complete ? complete.overallRating : 0,
        draftContentRating: type == FeedbackType.complete ? complete.contentRating : 0,
        draftExperienceRating: type == FeedbackType.complete ? complete.experienceRating : 0,
        draftReasons: type == FeedbackType.incomplete ? List.of(incomplete.reasons) : const [],
        draftComment: type == FeedbackType.complete ? complete.comment : incomplete.comment,
      ),
    );
  }

  void setActiveEntry(FeedbackEntry entry) => emit(state.copyWith(activeEntry: entry));

  void updateOverallRating(int rating) => emit(state.copyWith(draftOverallRating: rating));

  void updateContentRating(int rating) => emit(state.copyWith(draftContentRating: rating));

  void updateExperienceRating(int rating) => emit(state.copyWith(draftExperienceRating: rating));

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

  void setIncompleteFeedbackPrompt({
    required FeedbackEntry entry,
    required String courseId,
    required String lessonId,
    String keypointId = '',
  }) {
    if (courseId.isEmpty || lessonId.isEmpty) return;
    emit(
      state.copyWith(
        activeCourseId: courseId,
        activeLessonId: lessonId,
        activeKeypointId: keypointId,
        pendingFeedbackIncompletePrompt: entry,
      ),
    );
  }

  void clearIncompleteFeedbackPrompt() {
    emit(
      state.copyWith(
        pendingFeedbackIncompletePrompt: null,
      ),
    );
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
    final courseId = state.activeCourseId;
    final lessonId = state.activeLessonId;
    final keypointId = state.activeKeypointId;

    return UserFeedbackSubmissionEntity(
      userId: state.userFeedback.userId,
      courseId: courseId,
      lessonId: lessonId,
      keypointId: keypointId,
      type: state.activeType,
      entry: state.activeEntry,
      overallRating: 0,
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
            overallRating: submission.overallRating,
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
          overallRating: submission.overallRating,
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
