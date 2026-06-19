part of '../../../progress.dart';

@lazySingleton
class ProgressCubit extends Cubit<ProgressState> with CubitUseCaseHandlerMixin<ProgressState>, ProgressCubitCompletedLevelContentRequestMixin {
  final GetAllUserProgresssUseCase _getAllUserProgresssUseCase;
  final GetUserProgressLessonUseCase _getUserProgressLessonUseCase;
  final GetUserProgressKeypointUseCase _getUserProgressKeypointUseCase;
  final GetUserProgressExerciseUseCase _getUserProgressExerciseUseCase;
  final UpdateUserProgressLessonUseCase _updateUserProgressLessonUseCase;
  final UpdateUserProgressKeypointUseCase _updateUserProgressKeypointUseCase;
  final UpdateUserProgressExerciseUseCase _updateUserProgressExerciseUseCase;
  final GetUserProgressMyCoursesUseCase _getUserProgressMyCoursesUseCase;
  final CreateCompletedLevelAdditionalContentRequestUseCase _createCompletedLevelAdditionalContentRequestUseCase;

  final HomeCubit _homeCubit;
  final CourseLessonCubit _courseLessonCubit;
  final CourseRoadmapCubit _courseRoadmapCubit;
  final UserCubit _userCubit;
  final RoleplayCubit _roleplayCubit;
  int _courseProgressRequestSerial = 0;

  @override
  CreateCompletedLevelAdditionalContentRequestUseCase get completedLevelRequestUseCase => _createCompletedLevelAdditionalContentRequestUseCase;

  @override
  HomeCubit get completedLevelRequestHomeCubit => _homeCubit;

  @override
  CourseRoadmapCubit get completedLevelRequestRoadmapCubit => _courseRoadmapCubit;

  @override
  UserCubit get completedLevelRequestUserCubit => _userCubit;

  ProgressCubit(
    this._getAllUserProgresssUseCase,
    this._getUserProgressLessonUseCase,
    this._getUserProgressKeypointUseCase,
    this._getUserProgressExerciseUseCase,
    this._updateUserProgressLessonUseCase,
    this._updateUserProgressKeypointUseCase,
    this._updateUserProgressExerciseUseCase,
    this._getUserProgressMyCoursesUseCase,
    this._createCompletedLevelAdditionalContentRequestUseCase,
    this._homeCubit,
    this._courseLessonCubit,
    this._courseRoadmapCubit,
    this._userCubit,
    this._roleplayCubit,
  ) : super(ProgressState.initial());

  void reset() => emit(ProgressState.initial());

  Future<void> loadAllUserProgresss({String? userId, String? courseId, String? lessonId, bool silent = false}) async {
    if (!silent && state.status == ProgressStatus.loading) return;

    final String requestUserId = userId?.trim().isNotEmpty == true ? userId!.trim() : _userCubit.state.user.id;
    final String requestCourseId = courseId?.trim().isNotEmpty == true ? courseId!.trim() : _homeCubit.state.currentCourse.id;
    final String? requestLessonId = lessonId?.trim().isNotEmpty == true ? lessonId!.trim() : null;
    final int requestSerial = ++_courseProgressRequestSerial;
    final UserProgressFilter filter = UserProgressFilter(
      userId: requestUserId,
      courseId: requestCourseId,
      lessonId: requestLessonId,
      grade: UserProgressFilterType.course,
    );

    await runUseCase<UserProgressEntity>(
      usecase: () => _getAllUserProgresssUseCase(filter),
      buildLoadingState: () => silent ? state : state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        if (!_isLatestCourseProgressRequest(requestSerial)) return;
        emit(state.copyWith(status: silent ? state.status : ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        if (!_isLatestCourseProgressRequest(requestSerial)) return;
        emit(state.copyWith(status: silent ? state.status : ProgressStatus.success, userCourseProgress: item, errorMessage: null));
      },
    );
  }

  bool _isLatestCourseProgressRequest(int requestSerial) => requestSerial == _courseProgressRequestSerial;

  void loadUserProgressLesson({String? userId, String? courseId, String? lessonId, void Function(LessonResultEntity)? onSuccess}) async {
    if (state.status == ProgressStatus.loading) return;

    final String requestUserId = userId ?? _userCubit.state.user.id;
    final String requestCourseId = courseId ?? _homeCubit.state.currentCourse.id;
    final String requestLessonId = lessonId ?? _courseLessonCubit.state.selectedLesson.id;
    final UserProgressFilter filter = UserProgressFilter(
      userId: requestUserId,
      courseId: requestCourseId,
      lessonId: requestLessonId,
      grade: UserProgressFilterType.lesson,
    );

    await runUseCase<LessonResultEntity>(
      usecase: () => _getUserProgressLessonUseCase(filter),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, currentLessonResult: item));
        onSuccess?.call(item);
      },
    );
  }

  void loadUserProgressKeypoint({String? userId, String? courseId, String? lessonId, String? keypointId}) async {
    if (state.status == ProgressStatus.loading) return;

    final String requestUserId = userId ?? _userCubit.state.user.id;
    final String requestCourseId = courseId ?? _homeCubit.state.currentCourse.id;
    final String requestLessonId = lessonId ?? _courseLessonCubit.state.selectedLesson.id;
    final UserProgressFilter filter = UserProgressFilter(
      userId: requestUserId,
      courseId: requestCourseId,
      lessonId: requestLessonId,
      keypointId: keypointId,
      grade: UserProgressFilterType.keypoint,
    );

    await runUseCase<KeypointResultEntity>(
      usecase: () => _getUserProgressKeypointUseCase(filter),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, currentKeypointResult: item));
      },
    );
  }

  void loadUserProgressExercise({String? userId, String? courseId, String? lessonId, String? keypointId, String? exerciseId}) async {
    if (state.status == ProgressStatus.loading) return;

    final String requestUserId = userId ?? _userCubit.state.user.id;
    final String requestCourseId = courseId ?? _homeCubit.state.currentCourse.id;
    final String requestLessonId = lessonId ?? _courseLessonCubit.state.selectedLesson.id;
    final UserProgressFilter filter = UserProgressFilter(
      userId: requestUserId,
      courseId: requestCourseId,
      lessonId: requestLessonId,
      keypointId: keypointId,
      exerciseId: exerciseId,
      grade: UserProgressFilterType.exercise,
    );

    await runUseCase<ExerciseResultEntity>(
      usecase: () => _getUserProgressExerciseUseCase(filter),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success, currentExerciseResult: item));
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
        emit(state.copyWith(status: ProgressStatus.success));
        final courseId = params.body["courseId"]?.toString() ?? '';
        _courseRoadmapCubit.loadRoadmap(courseId: courseId);
        if (courseId.isNotEmpty) {
          unawaited(loadAllUserProgresss(courseId: courseId, silent: true));
        }
        HomeWidgetSyncTrigger.requestDebouncedSync(changedCourseId: courseId);
      },
    );
  }

  void updateUserProgressKeypoint(LessonType lessonType, UpdateUserProgressKeypointParams params, {String lessonReview = ''}) async {
    final String userId = _userCubit.state.user.id;
    final CourseLessonState courseLessonState = _courseLessonCubit.state;
    final LessonEntity lessonEntity = _roleplayCubit.state.currentLesson;
    final String courseId = resolveLessonFlowCourseId(
      lessonCourseId: switch (lessonType) {
        LessonType.lesson || LessonType.video => courseLessonState.selectedLesson.courseId,
        LessonType.roleplay => lessonEntity.courseId,
        _ => '',
      },
      roadmapCourseId: _courseRoadmapCubit.state.roadmap.courseId,
      homeCourseId: _homeCubit.state.currentCourse.id,
    );
    String lessonId = '';

    switch (lessonType) {
      case LessonType.lesson || LessonType.video:
        lessonId = courseLessonState.selectedLesson.id;
        break;
      case LessonType.roleplay:
        lessonId = lessonEntity.id;
        break;
      case LessonType.output:
        lessonId = '';
        break;
      case LessonType.unknown || LessonType.video:
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
          updateUserProgressLesson(
            UpdateUserProgressLessonParams(
              lessonId: lessonId,
              body: {
                "userId": userId,
                "courseId": courseId,
                "averageScore": params.keypoints.first.averageScore,
                "passed": params.keypoints.first.passed,
                "reviews": lessonReview.isNotEmpty ? lessonReview : params.keypoints.first.reviews,
              },
            ),
          );
        }
        emit(state.copyWith(status: ProgressStatus.success));
        _courseLessonCubit.loadLesson(courseLessonState.selectedLesson.id);
        _courseRoadmapCubit.loadRoadmap(courseId: courseId);
        unawaited(loadAllUserProgresss(courseId: courseId, silent: true));
        loadUserProgressMyCourses(isInit: true, recent: true);
        HomeWidgetSyncTrigger.requestDebouncedSync(changedCourseId: courseId);

        AppDI.injector.get<AchievenmentProgressCubit>()
          ..loadCourseLevelProgress(courseId)
          ..loadAllAchievenmentResponses();
      },
    );
  }

  void updateUserProgressExercise(UpdateUserProgressExerciseParams params) async {
    await runUseCase<UserProgressEntity>(
      usecase: () => _updateUserProgressExerciseUseCase(params),
      buildLoadingState: () => state.copyWith(status: ProgressStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: ProgressStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: ProgressStatus.success));
        HomeWidgetSyncTrigger.requestDebouncedSync(changedCourseId: params.courseId ?? '');
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
