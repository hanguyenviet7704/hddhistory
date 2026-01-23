part of '../../../course.dart';

@lazySingleton
class CourseRoadmapCubit extends HydratedCubit<CourseRoadmapState> with CubitUseCaseHandlerMixin<CourseRoadmapState> {
  final GetRoadmapUseCase _getRoadmapUseCase;

  CourseRoadmapCubit(
    this._getRoadmapUseCase,
  ) : super(CourseRoadmapState.initial());

  @override
  CourseRoadmapState fromJson(Map<String, dynamic> json) => CourseRoadmapState.fromJson(json);

  @override
  Map<String, dynamic> toJson(CourseRoadmapState state) => state.toJson();

  void reset() => emit(CourseRoadmapState.initial());

  void setRoadmapSource(String source) => emit(state.copyWith(roadmapSource: source));

  void setCurrentLevelProgress(List<CourseLevelProgressEntity> courseLevelProgresses) async {
    if (state.roadmap.levels.isEmpty) return;
    final CourseLevelProgressEntity currentLevelProgress = courseLevelProgresses.firstWhere(
      (progress) => progress.level == state.currentCourseLevel && progress.courseId == state.roadmap.courseId,
      orElse: () => CourseLevelProgressEntity(),
    );
    emit(state.copyWith(currentLevelProgress: currentLevelProgress));
  }

  void setCurrentCourseLevel(CourseLevel level) => emit(state.copyWith(currentCourseLevel: level));

  void setCurrentLesson(LessonEntity lesson) => emit(state.copyWith(currentLesson: lesson));

  void loadRoadmap({String courseId = ''}) async {
    if (courseId.isEmpty) {
      courseId = state.roadmap.courseId;
    }
    if (courseId.isEmpty) return;

    await runUseCase<RoadmapEntity>(
      usecase: () => _getRoadmapUseCase(courseId),
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (roadmap) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            roadmap: roadmap,
          ),
        );
      },
    );
  }
}
