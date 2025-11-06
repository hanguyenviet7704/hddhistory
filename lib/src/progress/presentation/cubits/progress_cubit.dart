part of '../../progress.dart';

@lazySingleton
class ProgressCubit extends Cubit<ProgressState> with CubitUseCaseHandlerMixin<ProgressState> {
  final UpdateUserProgressLessonUseCase _updateUserProgressLessonUseCase;
  final UpdateUserProgressKeypointUseCase _updateUserProgressKeypointUseCase;
  final UpdateUserProgressExerciseUseCase _updateUserProgressExerciseUseCase;
  final GetAllUserProgresssUseCase _getAllUserProgresssUseCase;
  final GetUserProgressMyCoursesUseCase _getUserProgressMyCoursesUseCase;

  ProgressCubit(
    this._getAllUserProgresssUseCase,
    this._updateUserProgressLessonUseCase,
    this._updateUserProgressKeypointUseCase,
    this._updateUserProgressExerciseUseCase,
    this._getUserProgressMyCoursesUseCase,
  ) : super(ProgressState.initial());

  void loadAllUserProgresss({bool isInit = false}) async {
    if (!isInit && state.status == ProgressStatus.loading) return;
    if (!isInit && state.pageData.isLastPage) return;

    PageBreakRequest pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.pageData.nextPage);

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

  void updateUserProgressLesson(String lessonId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressLessonUseCase(lessonId),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedLesson: item));
      },
    );
  }

  void updateUserProgressKeypoint(String keypointId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressKeypointUseCase(keypointId),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedKeypoint: item));
      },
    );
  }

  void updateUserProgressExercise(String exerciseId) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressExerciseUseCase(exerciseId),
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

    PageBreakRequest pageRequest = isInit ? const PageBreakRequest() : PageBreakRequest(page: state.myCoursesPageData.nextPage);

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
