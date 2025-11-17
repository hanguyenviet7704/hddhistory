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

  void updateUserProgressLesson(UpdateUserProgressLessonParams params) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressLessonUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedLesson: item));
        AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(params.body["courseId"]);
      },
    );
  }

  void updateUserProgressKeypoint(LessonType lessonType, UpdateUserProgressKeypointParams params) async {
    final String userId = AppDI.injector.get<UserCubit>().state.user.id;
    final String courseId = AppDI.injector.get<HomeCubit>().state.currentCourse.id;
    final CourseLessonState courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final LessonEntity lessonEntity = AppDI.injector.get<RoleplayCubit>().lesson;
    String lessonId = '';

    switch (lessonType) {
      case LessonType.lesson:
        lessonId = courseLessonState.selectedLesson.id;
        break;
      case LessonType.roleplay:
        lessonId = lessonEntity.id;
        break;
      case LessonType.output:
        lessonId = '';
        break;
    }

    params = params.copyWith(
      userId: userId,
      courseId: courseId,
      lessonId: lessonId,
    );

    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressKeypointUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        if ((lessonType == LessonType.lesson && courseLessonState.isAllOtherKeypointsCompleted) || (lessonType == LessonType.roleplay)) {
          _updateUserProgressLesson(
            lessonId,
            {
              "userId": userId,
              "courseId": courseId,
              "averageScore": params.keypoints.first.averageScore,
              "passed": params.keypoints.first.passed,
              "reviews": params.keypoints.first.reviews,
            },
          );
        }
        emit(state.copyWith(status: ProgressStatus.success, selectedKeypoint: item));
        AppDI.injector.get<CourseLessonCubit>().loadLesson(courseLessonState.selectedLesson.id);
        AppDI.injector.get<CourseRoadmapCubit>().loadRoadmap(courseId);
        loadUserProgressMyCourses(isInit: true, recent: true);
      },
    );
  }

  void _updateUserProgressLesson(String lessonId, Map<String, dynamic> body) async {
    updateUserProgressLesson(UpdateUserProgressLessonParams(lessonId: lessonId, body: body));
  }

  void updateUserProgressExercise(UpdateUserProgressExerciseParams params) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressExerciseUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, selectedExercise: item));
      },
    );
  }

  Future<void> loadUserProgressMyCourses({bool isInit = false, bool recent = false}) async {
    if (!isInit && state.status == ProgressStatus.loading) return;
    if (!isInit && state.myCoursesPageData.isLastPage) return;
    UserProgressMyCoursesUseCaseFilter filter = UserProgressMyCoursesUseCaseFilter(recent: recent);
    PageBreakRequest pageRequest = isInit
        ? PageBreakRequest(filter: filter)
        : PageBreakRequest(
            page: state.myCoursesPageData.nextPage,
            filter: filter,
          );

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
