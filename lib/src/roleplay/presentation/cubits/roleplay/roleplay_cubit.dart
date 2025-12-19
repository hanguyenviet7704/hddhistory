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

  void goToNextSection() {
    // if (nextIndex >= state.currentLearningItem.sections.length) {
    //   AppDI.injector.get<RoleplayPointCubit>().finishRoleplayLesson();
    //   _sendFeedback();
    //   RoleplayCompleteRoute().go(AppConfig.instance.context!);
    //   return;
    // }
    if (state.currentRoleplay.contents.last.type == RoleplayContentType.exercise) {
      setLearningItemToLessonCubit();
      LessonRoute().push(AppConfig.instance.context!);
    }
  }

  void setCurrentSectionRevealed(bool isRevealed) {
    if (state.isCurrentSectionRevealed == isRevealed) return;
    emit(state.copyWith(isCurrentSectionRevealed: isRevealed));
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

      final updatedResult = content.exercise.result.copyWith(
        textAnswer: (textAnswer != null && textAnswer.isNotEmpty) ? textAnswer : content.exercise.result.textAnswer,
        recordPath: (recordPath != null && recordPath.isNotEmpty) ? recordPath : content.exercise.result.recordPath,
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
