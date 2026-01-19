part of '../../../course.dart';

@lazySingleton
class CourseLessonCubit extends Cubit<CourseLessonState> with CubitUseCaseHandlerMixin<CourseLessonState> {
  final GetCourseLessonUseCase _getCourseLessonUseCase;

  CourseLessonCubit(
    this._getCourseLessonUseCase,
  ) : super(CourseLessonState.initial());

  void reset() => emit(CourseLessonState.initial());
  void setCurrentKeypointId(String id) => emit(state.copyWith(currentKeypointId: id));

  void loadLesson(String id) async {
    String requestId = id;
    if (requestId.isEmpty) {
      requestId = state.selectedLesson.id;
    }
    if (requestId.isEmpty) return;

    await runUseCase<LessonEntity>(
      usecase: () => _getCourseLessonUseCase(requestId),
      buildLoadingState: () {
        if (state.selectedLesson.keypoints.isNotEmpty) return state;
        return state.copyWith(status: CourseLessonStatus.loading);
      },
      onFailure: (error) {
        emit(state.copyWith(status: CourseLessonStatus.failure, errorMessage: error));
      },
      onSuccess: (lesson) {
        emit(state.copyWith(status: CourseLessonStatus.success, selectedLesson: lesson));
        checkAndFinishOptionalKeypoints();
      },
    );
  }

  void checkAndFinishOptionalKeypoints() {
    final courseConfig = AppService.instance.remoteConfigService.courseConfig;
    if (!courseConfig.finishOptionalKeypoints) return;
    if (state.selectedLesson.keypoints.isEmpty) return;
    final LessonResultEntity currentLessonResult = AppDI.injector.get<ProgressCubit>().state.currentLessonResult;
    final LessonEntity lesson = state.updateLessonWithResults(currentLessonResult);
    List<KeypointEntity> optionalKeypoints = lesson.keypoints.where((keypoint) => keypoint.strengthLevel == StrengthLevel.optionalPractice).toList();
    if (optionalKeypoints.isEmpty) return;
    for (var keypoint in optionalKeypoints) {
      if (keypoint.progess == ProcessEnum.done) continue;
      UpdateUserProgressKeypointData keypointData = UpdateUserProgressKeypointData(
        keypointId: keypoint.id,
        averageScore: 0.0,
        passed: true,
        reviews: '',
      );
      UpdateUserProgressKeypointParams keypointParams = UpdateUserProgressKeypointParams(keypoints: [keypointData]);
      AppDI.injector.get<ProgressCubit>().updateUserProgressKeypoint(LessonType.lesson, keypointParams);
    }
  }
}
