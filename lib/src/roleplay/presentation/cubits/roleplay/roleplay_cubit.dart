part of '../../../roleplay.dart';

@lazySingleton
class RoleplayCubit extends Cubit<RoleplayState> with CubitUseCaseHandlerMixin<RoleplayState> {
  final GetRoleplayLearningItemUseCase _getLearningItemUseCase;
  final SendFeedbackRoleplayUseCase _sendFeedbackRoleplayUseCase;

  RoleplayCubit(
    this._getLearningItemUseCase,
    this._sendFeedbackRoleplayUseCase,
  ) : super(RoleplayState.initial());

  LessonEntity lesson = LessonEntity();

  void reset() => emit(RoleplayState.initial());
  void resetIndex() => emit(state.copyWith(currentSectionIndex: 0));
  void setLessonId(LessonEntity lesson) => this.lesson = lesson;

  void setLearningItemToLessonCubit() {
    LearningItemEntity learningItem = state.currentLearningItem;
    learningItem = learningItem.copyWith(
      sectionQuestionIndex: state.currentSectionIndex,
      isPlayingRoleplayQuestions: true,
    );
    AppDI.injector.get<LessonCubit>().setLearningItemFromRoleplay(learningItem);
  }

  void goToNextSection() {
    final nextIndex = state.currentSectionIndex + 1;
    if (nextIndex >= state.currentLearningItem.sections.length) {
      AppDI.injector.get<RoleplayPointCubit>().finishRoleplayLesson();
      _sendFeedback();
      RoleplayCompleteRoute().go(AppConfig.instance.context!);
      return;
    }
    emit(state.copyWith(currentSectionIndex: nextIndex, isCurrentSectionRevealed: false));
    if (state.currentSection.contents.last.type == RoleplaySectionType.exercise) {
      setLearningItemToLessonCubit();
      LessonRoute().push(AppConfig.instance.context!);
    }
  }

  void setCurrentSectionRevealed(bool isRevealed) {
    if (state.isCurrentSectionRevealed == isRevealed) return;
    emit(state.copyWith(isCurrentSectionRevealed: isRevealed));
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
