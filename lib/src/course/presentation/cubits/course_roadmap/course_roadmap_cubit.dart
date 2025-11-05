part of '../../../course.dart';

@lazySingleton
class CourseRoadmapCubit extends Cubit<CourseRoadmapState> with CubitUseCaseHandlerMixin<CourseRoadmapState> {
  final GetAllCoursesUseCase _getAllCoursesUseCase;
  final GetCourseUseCase _getCourseUseCase;
  final GetRoadmapUseCase _getRoadmapUseCase;

  CourseRoadmapCubit(
    this._getAllCoursesUseCase,
    this._getCourseUseCase,
    this._getRoadmapUseCase,
  ) : super(CourseRoadmapState.initial());

  void loadAllCourses({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == CourseRoadmapStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<CourseEntity>(
      usecase: () => _getAllCoursesUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            pageData: pageData,
          ),
        );
      },
    );
  }

  void loadCourse(String id) async {
    await runUseCase<CourseEntity>(
      usecase: () => _getCourseUseCase(id),
      buildLoadingState: () => state.copyWith(status: CourseRoadmapStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: CourseRoadmapStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }

  void loadRoadmap(String courseId) async {
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
