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
