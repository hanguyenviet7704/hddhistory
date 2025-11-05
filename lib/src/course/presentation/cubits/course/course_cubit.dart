part of '../../../course.dart';

@lazySingleton
class CourseCubit extends Cubit<CourseState> with CubitUseCaseHandlerMixin<CourseState> {
  final GetAllCoursesUseCase _getAllCoursesUseCase;
  final GetCourseUseCase _getCourseUseCase;

  CourseCubit(
    this._getAllCoursesUseCase,
    this._getCourseUseCase,
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
      usecase: () => _getAllCoursesUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: CourseStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (pageData) {
        emit(
          state.copyWith(
            status: CourseStatus.success,
            pageData: pageData,
          ),
        );
      },
    );
  }

  void loadCourse(String id) async {
    await runUseCase<CourseEntity>(
      usecase: () => _getCourseUseCase(id),
      buildLoadingState: () => state.copyWith(status: CourseStatus.loading),
      onFailure: (error) {
        emit(
          state.copyWith(
            status: CourseStatus.failure,
            errorMessage: error,
          ),
        );
      },
      onSuccess: (item) {
        emit(
          state.copyWith(
            status: CourseStatus.success,
            selectedItem: item,
          ),
        );
      },
    );
  }

}
