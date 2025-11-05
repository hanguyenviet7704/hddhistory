part of '../../progress.dart';

@lazySingleton
class ProgressCubit extends Cubit<ProgressState> with CubitUseCaseHandlerMixin<ProgressState> {
  final GetAllUserProgresssUseCase _getAllUserProgresssUseCase;
  final GetUserProgressLessonUseCase _getUserProgressLessonUseCase;
  final GetUserProgressKeypointUseCase _getUserProgressKeypointUseCase;
  final GetUserProgressExerciseUseCase _getUserProgressExerciseUseCase;
  final GetUserProgressMyCoursesUseCase _getUserProgressMyCoursesUseCase;

  ProgressCubit(
    this._getAllUserProgresssUseCase,
    this._getUserProgressLessonUseCase,
    this._getUserProgressKeypointUseCase,
    this._getUserProgressExerciseUseCase,
    this._getUserProgressMyCoursesUseCase,
  ) : super(ProgressState.initial());

  void loadAllUserProgresss({bool isInit = false}) async {
    if (!isInit && state.status == ProgressStatus.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest = isInit 
      ? const PageBreakRequest() 
      : PageBreakRequest(page: state.pageData.nextPage);

    await runUseCasePageBreak<UserProgressEntity>(
      usecase: () => _getAllUserProgresssUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: ProgressStatus.success, pageData: pageData));
      },
    );
  }

  void loadUserProgressLesson(String lessonId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _getUserProgressLessonUseCase(lessonId),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedLesson: item));
      },
    );
  }

  void loadUserProgressKeypoint(String keypointId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _getUserProgressKeypointUseCase(keypointId),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedKeypoint: item));
      },
    );
  }

  void loadUserProgressExercise(String exerciseId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _getUserProgressExerciseUseCase(exerciseId),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedExercise: item));
      },
    );
  }

  void loadUserProgressMyCourses({bool isInit = false}) async {
    if (!isInit && state.status == ProgressStatus.loading) return;
    if (!isInit && state.myCoursesPageData.isLastPage) return;

    PageBreakRequest pageRequest = isInit 
      ? const PageBreakRequest() 
      : PageBreakRequest(page: state.myCoursesPageData.nextPage);

    await runUseCasePageBreak<CourseEntity>(
      usecase: () => _getUserProgressMyCoursesUseCase(pageRequest),
      currentPageData: state.myCoursesPageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: ProgressStatus.success, myCoursesPageData: pageData));
      },
    );
  }
}

