part of '../../course.dart';

@lazySingleton
class CourseLessonCubit extends Cubit<CourseLessonState> with CubitUseCaseHandlerMixin<CourseLessonState> {
  final GetAllLessonsUseCase _getAllLessonsUseCase;
  final GetLessonUseCase _getLessonUseCase;

  CourseLessonCubit(
    this._getAllLessonsUseCase,
    this._getLessonUseCase,
  ) : super(CourseLessonState.initial());

  void loadAllLessons({
    bool isInit = false,
  }) async {
    if (!isInit && state.status == CourseLessonStatus.loading) return;

    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest;
    pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<LessonEntity>(
      usecase: () => _getAllLessonsUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: CourseLessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: CourseLessonStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(
          status: CourseLessonStatus.success,
          pageData: pageData,
        ));
      },
    );
  }

  void loadLesson(String id) async {
    await runUseCase<LessonEntity>(
      usecase: () => _getLessonUseCase(id),
      buildLoadingState: () => state.copyWith(status: CourseLessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(
          status: CourseLessonStatus.failure,
          errorMessage: error,
        ));
      },
      onSuccess: (lesson) {
        emit(state.copyWith(
          status: CourseLessonStatus.success,
          selectedLesson: lesson,
        ));
      },
    );
  }
}

