part of '../../../progress.dart';

mixin ProgressCubitCompletedLevelContentRequestMixin on Cubit<ProgressState>, CubitUseCaseHandlerMixin<ProgressState> {
  CreateCompletedLevelAdditionalContentRequestUseCase get completedLevelRequestUseCase;
  HomeCubit get completedLevelRequestHomeCubit;
  CourseRoadmapCubit get completedLevelRequestRoadmapCubit;
  UserCubit get completedLevelRequestUserCubit;

  Future<bool> submitCompletedLevelAdditionalContentRequest({
    required CourseLevel level,
    required bool requested,
    String requestText = '',
    String? courseId,
    String? userId,
  }) async {
    if (state.isSubmittingCompletedLevelAdditionalContentRequest) return false;

    final levelValue = _completedLevelRequestLevelValue(level);
    final requestUserId = _resolvedCompletedLevelRequestUserId(userId);
    final requestCourseId = _resolvedCompletedLevelRequestCourseId(courseId);
    final trimmedRequestText = requestText.trim();

    if (levelValue.isEmpty || requestUserId.isEmpty || requestCourseId.isEmpty) {
      emit(state.copyWith(errorMessage: 'Missing required completed-level request data.'));
      return false;
    }

    var succeeded = false;
    await runUseCase<UserProgressEntity>(
      usecase: () => completedLevelRequestUseCase({
        'userId': requestUserId,
        'courseId': requestCourseId,
        'level': levelValue,
        'requested': requested,
        'requestText': trimmedRequestText,
      }),
      buildLoadingState: () => state.copyWith(
        isSubmittingCompletedLevelAdditionalContentRequest: true,
        errorMessage: null,
      ),
      onFailure: (error) {
        emit(
          state.copyWith(
            isSubmittingCompletedLevelAdditionalContentRequest: false,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        final nextProgress = item.completedLevels.isNotEmpty
            ? item
            : state.userCourseProgress.withCompletedLevelAdditionalContentRequest(
                level: level,
                requested: requested,
                requestText: trimmedRequestText,
                fallbackUserId: requestUserId,
                fallbackCourseId: requestCourseId,
              );
        emit(
          state.copyWith(
            userCourseProgress: nextProgress,
            isSubmittingCompletedLevelAdditionalContentRequest: false,
            errorMessage: null,
          ),
        );
        succeeded = true;
      },
    );

    return succeeded;
  }

  String _resolvedCompletedLevelRequestUserId(String? explicitUserId) {
    final currentUserId = completedLevelRequestUserCubit.state.user.id.trim();
    if (currentUserId.isNotEmpty) return currentUserId;
    return explicitUserId?.trim() ?? '';
  }

  String _resolvedCompletedLevelRequestCourseId(String? explicitCourseId) {
    final ids = [
      explicitCourseId,
      completedLevelRequestRoadmapCubit.state.roadmap.courseId,
      completedLevelRequestHomeCubit.state.currentCourse.id,
    ];
    for (final id in ids) {
      final trimmedId = id?.trim() ?? '';
      if (trimmedId.isNotEmpty) return trimmedId;
    }
    return '';
  }

  String _completedLevelRequestLevelValue(CourseLevel level) {
    return switch (level) {
      CourseLevel.level1 => 'level 1',
      CourseLevel.level2 => 'level 2',
      CourseLevel.unknown => '',
    };
  }
}
