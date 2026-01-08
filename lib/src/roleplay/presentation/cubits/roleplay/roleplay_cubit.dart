part of '../../../roleplay.dart';

@lazySingleton
class RoleplayCubit extends Cubit<RoleplayState> with CubitUseCaseHandlerMixin<RoleplayState> {
  final GetRoleplayLearningItemUseCase _getLearningItemUseCase;
  final SendFeedbackRoleplayUseCase _sendFeedbackRoleplayUseCase;

  RoleplayCubit(
    this._getLearningItemUseCase,
    this._sendFeedbackRoleplayUseCase,
  ) : super(RoleplayState.initial());

  void reset() => emit(RoleplayState.initial());
  void setCurrentLesson(LessonEntity lesson) => emit(state.copyWith(currentLesson: lesson));

  void setLearningItemToLessonCubit() {
    LearningItemEntity learningItem = state.currentLearningItem;
    learningItem = learningItem.copyWith(
      isPlayingRoleplayQuestions: true,
    );
    AppDI.injector.get<LessonCubit>().setLearningItemFromRoleplay(learningItem);
  }

  void endRoleplay() {
    AppDI.injector.get<RoleplayPointCubit>().finishRoleplayLesson();
    _sendFeedback();
    RoleplayCompleteRoute().go(AppConfig.instance.context!);

    // if (state.currentRoleplay.contents.last.type == RoleplayContentType.exercise) {
    //   setLearningItemToLessonCubit();
    //   LessonRoute().push(AppConfig.instance.context!);
    // }
  }

  void setCurrentSectionRevealed(bool isRevealed) {
    if (state.isCurrentSectionRevealed == isRevealed) return;
    emit(state.copyWith(isCurrentSectionRevealed: isRevealed));
  }

  void setExerciseResult({
    required int contentId,
    required int contentIndex,
    required ExerciseResultEntity result,
  }) {
    final contents = state.currentRoleplay.contents;
    if (contents.isEmpty) return;
    int? targetIndex;

    if (contentId > 0) {
      final matchedIndices = <int>[];
      for (int i = 0; i < contents.length; i++) {
        final content = contents[i];
        if (content.id == contentId && content.type == RoleplayContentType.exercise) {
          matchedIndices.add(i);
        }
      }
      if (matchedIndices.length == 1) {
        targetIndex = matchedIndices.first;
      }
    }

    if (targetIndex == null) {
      if (contentIndex < 0 || contentIndex >= contents.length) return;
      if (contents[contentIndex].type != RoleplayContentType.exercise) return;
      targetIndex = contentIndex;
    }

    final updatedContents = contents.toList();
    updatedContents[targetIndex] = contents[targetIndex].copyWith(
      exercise: contents[targetIndex].exercise.copyWith(result: result),
    );

    emit(
      state.copyWith(
        currentLearningItem: state.currentLearningItem.copyWith(
          roleplay: state.currentRoleplay.copyWith(contents: updatedContents),
        ),
      ),
    );
  }

  void setExerciseRecordAnswer({
    required int questionId,
    String? textAnswer,
    String? recordPath,
  }) {
    if (state.currentRoleplay.contents.isEmpty) return;

    final updatedContents = state.currentRoleplay.contents.map((content) {
      if (content.type != RoleplayContentType.exercise || content.exercise.id != questionId) {
        return content;
      }

      final currentResult = content.exercise.result;
      final updatedResult = currentResult.copyWith(
        exerciseId: currentResult.exerciseId.isNotEmpty ? currentResult.exerciseId : content.exercise.id.toString(),
        type: content.exercise.type,
        form: content.exercise.form,
        recordAnswer: AnswerEntity(
          record: recordPath ?? currentResult.recordAnswer.record,
          review: textAnswer ?? currentResult.recordAnswer.review,
        ),
      );

      return content.copyWith(
        exercise: content.exercise.copyWith(result: updatedResult),
      );
    }).toList();

    emit(
      state.copyWith(
        currentLearningItem: state.currentLearningItem.copyWith(
          roleplay: state.currentRoleplay.copyWith(contents: updatedContents),
        ),
      ),
    );
  }

  void loadLearningItem(String id, {BaseMultiLanguage? estimateCompleTime}) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading, isCurrentSectionRevealed: false),
      onFailure: (error) {
        emit(state.copyWith(status: RoleplayStatus.failure, errorMessage: error, isCurrentSectionRevealed: false));
      },
      onSuccess: (item) {
        LearningItemEntity newItem = item.copyWith(estimateCompleTime: estimateCompleTime ?? item.estimateCompleTime);
        emit(state.copyWith(status: RoleplayStatus.success, currentLearningItem: newItem, isCurrentSectionRevealed: false));
        _loadUserProgressExercise();
      },
    );
  }

  void _loadUserProgressExercise() async {
    final lessonId = state.currentLesson.id;
    final courseId = AppDI.injector.get<CourseRoadmapCubit>().state.roadmap.courseId;
    final userId = AppDI.injector.get<UserCubit>().state.user.id;
    final currentRoleplayId = state.currentRoleplay.id;
    AppDI.injector.get<ProgressCubit>().loadUserProgressLesson(
      userId: userId,
      courseId: courseId,
      lessonId: lessonId,
      onSuccess: (result) {
        if (currentRoleplayId != state.currentRoleplay.id) return;
        if (result.exercisesResult.isEmpty) return;

        final Map<String, ExerciseResultEntity> resultsById = {
          for (final exerciseResult in result.exercisesResult)
            if (exerciseResult.exerciseId.isNotEmpty) exerciseResult.exerciseId: exerciseResult,
        };

        final updatedContents = state.currentRoleplay.contents.map((content) {
          if (content.type != RoleplayContentType.exercise) return content;
          final exerciseId = content.exercise.id.toString();
          final matchedResult = resultsById[exerciseId];
          if (matchedResult == null) return content;

          return content.copyWith(
            exercise: content.exercise.copyWith(result: matchedResult),
          );
        }).toList();

        emit(
          state.copyWith(
            currentLearningItem: state.currentLearningItem.copyWith(
              roleplay: state.currentRoleplay.copyWith(contents: updatedContents),
            ),
          ),
        );
      },
    );
  }

  void _sendFeedback() async {
    final points = AppDI.injector.get<RoleplayPointCubit>().state.points;
    final languageCode = AppDI.injector.get<LocaleCubit>().state.languageCode;

    final theory = <String, String>{};
    final keypointScore = <String, int>{};

    for (final keypoint in points) {
      final title = keypoint.title.text;
      theory[title] = keypoint.description.text;
      keypointScore[title] = keypoint.point;
    }

    final body = <String, dynamic>{
      'theory': theory,
      'keypoint_score': keypointScore,
      'language_feedback': languageCode,
    };

    await runUseCase<RoleplayFeedbackEntity>(
      usecase: () => _sendFeedbackRoleplayUseCase(body),
      buildLoadingState: () => state.copyWith(status: RoleplayStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: RoleplayStatus.failure, errorMessage: error));
      },
      onSuccess: (feedback) {
        emit(state.copyWith(status: RoleplayStatus.success, feedback: feedback));
      },
    );
  }
}
