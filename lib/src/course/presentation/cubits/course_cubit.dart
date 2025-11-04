part of '../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  final GetAllCoursesUseCase _getAllUseCase;
  final GetCourseUseCase _getUseCase;
  final GetRoadmapUseCase _getRoadmapUseCase;

  CourseCubit(
    this._getAllUseCase,
    this._getUseCase,
    this._getRoadmapUseCase,
  ) : super(CourseState.initial());

  void loadAllCourses({
    bool isInit = false,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == CourseStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<CourseEntity>(
      usecase: () => _getAllUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: CourseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: CourseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: CourseStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadCourse(String id) async {
    await runUseCase<CourseEntity>(
      usecase: () => _getUseCase(id),
      buildLoadingState: () => state.copyWith(status: CourseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: CourseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (item) {
        emit(state.copyWith(
          status: CourseStatus.success,
          selectedItem: item,
        ));
      },
    );
  }

  void loadRoadmap(String courseId) async {
    await runUseCase<RoadmapEntity>(
      usecase: () => _getRoadmapUseCase(courseId),
      buildLoadingState: () => state.copyWith(status: CourseStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: CourseStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (roadmap) {
        emit(state.copyWith(
          status: CourseStatus.success,
          roadmap: roadmap,
        ));
      },
    );
  }
}

