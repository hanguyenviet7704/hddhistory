part of '../../../lesson.dart';

@lazySingleton
class LessonCubit extends Cubit<LessonState> with CubitUseCaseHandlerMixin<LessonState> {
  final GetAllLearningItemsUseCase _getAllLearningItemUseCase;
  final GetLearningItemUseCase _getLearningItemUseCase;
  final ProgressCubit _progressCubit;
  final ExerciseCubit _exerciseCubit;
  final TheoryCubit _theoryCubit;

  LessonCubit(
    this._getAllLearningItemUseCase,
    this._getLearningItemUseCase,
    this._progressCubit,
    this._exerciseCubit,
    this._theoryCubit,
  ) : super(LessonState.initial());

  // Course id the `live_scr_view` proxy was last fired for, so restarting the
  // same Live Activity card (or an update()) doesn't refire the event.
  String? _liveScrViewTrackedCourseId;

  void reset() => emit(LessonState.initial());
  void setIsShowResultOverlay(bool value) => emit(state.copyWith(isShowResultOverlay: value));

  void setBottomButtonVisible(bool value) {
    if (state.isBottomButtonVisible == value) return;
    emit(state.copyWith(isBottomButtonVisible: value));
  }

  void setLearningItemFromRoleplay(LearningItemEntity learningItem) {
    emit(state.copyWith(pageData: state.pageData.copyWith(items: [learningItem]), currentLearningItemIndex: 0));
    setCurrentLearningItem(learningItem);
  }

  void setRoleplayDataToExerciseCubit(LearningItemEntity learningItem) {
    emit(state.copyWith(pageData: state.pageData.copyWith(items: [learningItem])));
    _exerciseCubit.setRoleplayQuestions(learningItem);
  }

  //* Lesson Page Flow
  void setCurrentLearningItem(LearningItemEntity learningItem) {
    if (learningItem.id.isEmpty) return;

    switch (learningItem.type) {
      case LearningItemType.theory:
        _theoryCubit
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
      case LearningItemType.exercise || LearningItemType.roleplay:
        _exerciseCubit
          ..reset()
          ..setCurrentLearningItem(learningItem);
        break;
      case LearningItemType.video:
        break;
      case LearningItemType.unknown:
        break;
    }
  }

  void nextLearningItem() {
    if (state.currentLearningItemIndex >= state.pageData.items.length - 1) {
      completeCurrentKeypoint();
      return;
    }

    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex + 1));
    setCurrentLearningItem(state.currentLearningItem);
    preloadNextLearningItem();
    unawaited(_updateLiveActivity());
  }

  void completeCurrentKeypoint({
    LessonCompletionOrigin origin = LessonCompletionOrigin.read,
    bool bypassReviewQueue = false,
  }) {
    if (!bypassReviewQueue && state.subQuestions.isNotEmpty) {
      ReviewTimeRoute().go(AppConfig.instance.context!);
      Future.delayed(const Duration(milliseconds: 100), () {
        AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.reviewTime);
      });
      return;
    }

    _updateUserProgressKeypoint();
    emit(state.copyWith(completionOrigin: origin));
    unawaited(_updateLiveActivity(keypointJustCompleted: true));
    KeypointCompleteRoute().go(AppConfig.instance.context!);
    Future.delayed(const Duration(milliseconds: 100), () {
      AppDI.injector.get<PageCubit>().setCurrentRouteName(RouteNamed.keypointComplete);
    });
  }

  void _updateUserProgressKeypoint() {
    UpdateUserProgressKeypointData keypointData = UpdateUserProgressKeypointData(
      keypointId: state.currentLearningItem.keypointId,
      averageScore: 0.0,
      passed: true,
      reviews: '',
    );

    UpdateUserProgressKeypointParams keypointParams = UpdateUserProgressKeypointParams(keypoints: [keypointData]);
    _progressCubit.updateUserProgressKeypoint(LessonType.lesson, keypointParams);
  }

  void previousLearningItem() {
    if (state.currentLearningItemIndex <= 0) return;
    emit(state.copyWith(currentLearningItemIndex: state.currentLearningItemIndex - 1));
    setCurrentLearningItem(state.currentLearningItem);
  }

  void setCurrentLessonIndex(int index) => emit(state.copyWith(currentLessonIndex: index));

  void addSubQuestion(QuestionEntity question) => emit(state.copyWith(subQuestions: [...state.subQuestions, question]));

  void markPendingAdvance() {
    if (state.hasPendingAdvance) return;
    if (state.currentLearningItem.type != LearningItemType.exercise) return;
    emit(state.copyWith(hasPendingAdvance: true));
  }

  void clearPendingAdvance() {
    if (!state.hasPendingAdvance) return;
    emit(state.copyWith(hasPendingAdvance: false));
  }

  void setSuppressNextAutoScroll() {
    if (state.suppressNextAutoScroll) return;
    emit(state.copyWith(suppressNextAutoScroll: true));
  }

  void clearSuppressNextAutoScroll() {
    if (!state.suppressNextAutoScroll) return;
    emit(state.copyWith(suppressNextAutoScroll: false));
  }

  void consumePendingAdvance() {
    if (!state.hasPendingAdvance) return;
    if (state.currentLearningItem.type != LearningItemType.exercise) return;
    emit(state.copyWith(hasPendingAdvance: false, suppressNextAutoScroll: true));
    AppDI.injector.get<ExerciseCubit>().nextQuestion();
  }

  void storeExerciseResult(QuestionEntity question, ExerciseResultEntity result) {
    if (state.currentLearningItem.type != LearningItemType.exercise) return;
    if (state.pageData.items.isEmpty) return;
    if (state.currentLearningItemIndex < 0 || state.currentLearningItemIndex >= state.pageData.items.length) return;

    final currentItem = state.pageData.items[state.currentLearningItemIndex];
    final questions = currentItem.questions;
    if (questions.isEmpty) return;

    final targetIndex = _resolveQuestionIndex(questions, question);
    if (targetIndex < 0 || targetIndex >= questions.length) return;

    final updatedQuestions = List<QuestionEntity>.from(questions);
    updatedQuestions[targetIndex] = updatedQuestions[targetIndex].copyWith(result: result);

    final updatedItem = currentItem.copyWith(mainQuestions: updatedQuestions);
    final updatedItems = List<LearningItemEntity>.from(state.pageData.items);
    updatedItems[state.currentLearningItemIndex] = updatedItem;

    emit(state.copyWith(pageData: state.pageData.copyWith(items: updatedItems)));
  }

  int _resolveQuestionIndex(List<QuestionEntity> questions, QuestionEntity question) {
    if (question.id != 0) {
      final index = questions.indexWhere((item) => item.id == question.id);
      if (index != -1) return index;
    }

    if (state.currentLessonIndex >= 0 && state.currentLessonIndex < questions.length) {
      return state.currentLessonIndex;
    }

    return -1;
  }

  void reviewDone() {
    if (state.subQuestions.isEmpty) {
      _updateUserProgressKeypoint();
      return;
    }

    LearningItemEntity learningItem = state.pageData.items.firstWhere((item) => item.type == LearningItemType.exercise, orElse: () => LearningItemEntity());
    learningItem = learningItem.copyWith(
      mainQuestions: state.subQuestions,
      type: LearningItemType.exercise,
      subQuestions: [],
      isPlayingSubQuestions: true,
    );
    _exerciseCubit.setSubQuestions(learningItem);
    List<LearningItemEntity> items = List<LearningItemEntity>.from(state.pageData.items);
    items.add(learningItem);
    emit(
      state.copyWith(
        pageData: state.pageData.copyWith(items: items),
        currentLearningItemIndex: items.length - 1,
        subQuestions: [],
      ),
    );
    LessonRoute().go(AppConfig.instance.context!);
  }

  void loadAllLearningItems({
    bool isInit = false,
    String? keypointId,
  }) async {
    // Prevent multiple simultaneous loads
    if (!isInit && state.status == LessonStatus.loading) return;

    // Prevent loading if already on last page (unless it's init)
    if (!isInit && state.pageData.isLastPage) return;

    LearningItemFilter filter = LearningItemFilter(keypointId: keypointId);

    PageBreakRequest<LearningItemFilter> pageRequest = isInit
        ? PageBreakRequest<LearningItemFilter>(filter: filter, orderBy: 'index', order: PageBreakOrder.asc)
        : PageBreakRequest<LearningItemFilter>(
            page: state.pageData.nextPage,
            filter: filter,
            orderBy: 'index',
            order: PageBreakOrder.asc,
          );

    await runUseCasePageBreak<LearningItemEntity>(
      usecase: () => _getAllLearningItemUseCase(pageRequest),
      currentPageData: state.pageData,
      isInit: isInit,
      buildLoadingState: () => state.copyWith(status: LessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonStatus.failure, errorMessage: error));
      },
      onSuccess: (pageData) {
        emit(state.copyWith(status: LessonStatus.success, pageData: pageData, currentLearningItemIndex: 0));
        if (pageData.items.isEmpty) return;
        loadLearningItem(
          pageData.items.first.id,
          onSuccess: (item) => setCurrentLearningItem(item),
        );
        preloadNextLearningItem();
        if (isInit) unawaited(_startLiveActivity());
      },
    );
  }

  /// Live Activity (Lock Screen + Dynamic Island) for the lesson just opened
  /// — best-effort, iOS 16.1+ only (see LiveActivityService), so failures here
  /// must never affect the actual lesson flow.
  Future<void> _startLiveActivity({String? preferredCourseId}) async {
    final context = _resolveLiveActivityCourseContext(preferredCourseId: preferredCourseId);
    if (context.courseId.isEmpty) return;

    String imagePath = '';
    if (context.courseImageUrl.isNotEmpty) {
      imagePath = await AppDI.injector.get<HomeWidgetBridge>().saveImageAndGetPath(
            key: 'meup_live_activity_course_image',
            imageUrl: context.courseImageUrl,
          ) ??
          '';
    }

    final copy = _liveActivityCopy(context.minutes, isDone: context.courseProgress >= 1);
    await AppDI.injector.get<LiveActivityService>().start(
          courseId: context.courseId,
          courseName: context.courseName,
          courseImagePath: imagePath,
          progress: context.courseProgress,
          isDone: context.courseProgress >= 1,
          inLessonLabel: copy.inLessonLabel,
          continueLearningLabel: copy.continueLearningLabel,
          resumeLabel: copy.resumeLabel,
          primaryNudge: copy.primaryNudge,
          footerNudge: copy.footerNudge,
        );
    // PROXY EVENT — `live_scr_view` is fired here, when the Live Activity card
    // is CREATED, NOT when the lock screen is actually viewed (Flutter can't
    // observe a real lock-screen impression; that is native/OS-only). Fired on
    // start() only (never on update()), and de-duped per course so a re-start
    // of the same card doesn't refire it.
    if (_liveScrViewTrackedCourseId != context.courseId) {
      _liveScrViewTrackedCourseId = context.courseId;
      unawaited(
        AppService.instance.appTrackingService
            .trackEvent(TrackingKey.liveScrView, parameters: {'course_id': context.courseId, 'course_name': context.courseName})
            .catchError((_) {}),
      );
    }
    await scheduleLiveActivityReturnNudge(courseId: context.courseId, courseName: context.courseName, isDone: false, minutes: context.minutes, progress: context.courseProgress);
  }

  /// Keeps a "resume this course" Live Activity alive while the user sits on the
  /// course roadmap (called by CourseRoadmapPage), so leaving the app from the
  /// roadmap — not only mid-lesson — still surfaces the card. Behaviour:
  /// - course finished → ends any card (nothing to resume, mirrors hiding the
  ///   roadmap's "Continue" CTA);
  /// - same course already showing → cheap update (fresh %), no flicker;
  /// - otherwise → starts a fresh card for [courseId].
  Future<void> ensureLiveActivityForRoadmap(String courseId) async {
    if (courseId.isEmpty) return;
    final context = _resolveLiveActivityCourseContext(preferredCourseId: courseId);
    if (context.courseId.isEmpty) return;

    final service = AppDI.injector.get<LiveActivityService>();
    if (context.courseProgress >= 1) {
      unawaited(service.end());
      unawaited(cancelLiveActivityReturnNudge());
      return;
    }

    if (service.activeCourseId == context.courseId) {
      final copy = _liveActivityCopy(context.minutes, isDone: false);
      await service.update(
            progress: context.courseProgress,
            isDone: false,
            resumeLabel: copy.resumeLabel,
            primaryNudge: copy.primaryNudge,
            footerNudge: copy.footerNudge,
          );
      await scheduleLiveActivityReturnNudge(courseId: context.courseId, courseName: context.courseName, isDone: false, minutes: context.minutes, progress: context.courseProgress);
      return;
    }

    await _startLiveActivity(preferredCourseId: courseId);
  }

  /// Reflects the latest course-level progress on the Live Activity — call on
  /// every learning-item transition, not on finer-grained state changes, so
  /// native updates stay infrequent. Uses the API-backed course progress
  /// (CourseRoadmapCubit.currentLevelProgress), NOT LessonState.progress —
  /// the latter is purely client-computed from the current lesson's local
  /// question/document index and doesn't reflect real course completion.
  Future<void> _updateLiveActivity({bool keypointJustCompleted = false}) async {
    final context = _resolveLiveActivityCourseContext();
    if (context.courseId.isEmpty) return;

    final progress = keypointJustCompleted ? context.optimisticProgressAfterKeypoint : context.courseProgress;
    final isDone = progress >= 1;
    final copy = _liveActivityCopy(context.minutes, isDone: isDone);
    await AppDI.injector.get<LiveActivityService>().update(
          progress: progress,
          isDone: isDone,
          resumeLabel: copy.resumeLabel,
          primaryNudge: copy.primaryNudge,
          footerNudge: copy.footerNudge,
        );
    await scheduleLiveActivityReturnNudge(courseId: context.courseId, courseName: context.courseName, isDone: isDone, minutes: context.minutes, progress: progress);
  }

  /// All Live Activity display copy, localized via slang for the current
  /// app locale (5 locales) — the native widget renders these verbatim and
  /// holds no English-only strings of its own.
  ({String inLessonLabel, String continueLearningLabel, String resumeLabel, String primaryNudge, String footerNudge}) _liveActivityCopy(int minutes, {required bool isDone}) {
    final lesson = l10n.lesson;
    final nudge = isDone ? lesson.liveActivityNudgeDone : lesson.liveActivityNudge(count: minutes);
    return (
      inLessonLabel: lesson.liveActivityInLesson,
      continueLearningLabel: lesson.liveActivityContinueLearning,
      resumeLabel: isDone ? lesson.liveActivityNextLesson : lesson.liveActivityResumeLesson,
      primaryNudge: nudge,
      footerNudge: isDone ? lesson.liveActivityCourseComplete : nudge,
    );
  }

  ({String courseId, String courseName, String courseImageUrl, int minutes, double courseProgress, double optimisticProgressAfterKeypoint}) _resolveLiveActivityCourseContext({String? preferredCourseId}) {
    final courseLessonState = AppDI.injector.get<CourseLessonCubit>().state;
    final roadmapState = AppDI.injector.get<CourseRoadmapCubit>().state;
    final homeState = AppDI.injector.get<HomeCubit>().state;
    // The roadmap passes its own courseId explicitly (its selectedLesson may be
    // stale/empty), otherwise fall back to the in-flight lesson flow's course.
    final courseId = (preferredCourseId != null && preferredCourseId.isNotEmpty)
        ? preferredCourseId
        : resolveLessonFlowCourseId(
            lessonCourseId: courseLessonState.selectedLesson.courseId,
            roadmapCourseId: roadmapState.roadmap.courseId,
            homeCourseId: homeState.currentCourse.id,
          );
    if (courseId.isEmpty) {
      return (courseId: '', courseName: '', courseImageUrl: '', minutes: _kDefaultLessonMinutes, courseProgress: 0, optimisticProgressAfterKeypoint: 0);
    }
    // Title/image come from the skillset list. Per-user lesson progress does
    // NOT — that endpoint always returns numberOfLessonPassed == 0 (see
    // all_course_tab.resolveCourseProgress). The real completion lives in
    // ProgressCubit.myCourses, the SAME source the Explore / Home course cards
    // read, so the Live Activity ring shows the exact % the user sees on the
    // card (e.g. "Hoàn thành 17%") instead of 0%.
    final displayCourse = homeState.skillsets.resolveCourseByCourseId(courseId, fallback: homeState.currentCourse);
    final progressCourse = _progressCubit.state.myCourses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => displayCourse,
    );
    final passed = progressCourse.numberOfLessonPassed;
    final total = progressCourse.numberOfLesson > 0 ? progressCourse.numberOfLesson : displayCourse.numberOfLesson;
    final courseProgress = total > 0 ? (passed / total).clamp(0.0, 1.0) : 0.0;
    // "~N min to finish the next lesson" — the lesson's own API-authored
    // estimate (estimateCompleTimeNumber, minutes), NOT scaled by course
    // progress: it's the time for the lesson you'd resume into, per the design
    // copy, not a countdown of the whole course. Falls back to the design's
    // default of 3 min when a lesson has no BTV-authored estimate.
    final estimate = courseLessonState.selectedLesson.estimateCompleTimeNumber;
    // Optimistic post-completion progress: the keypoint update is
    // fire-and-forget, so myCourses still holds the pre-completion count at the
    // moment completeCurrentKeypoint fires. A keypoint completes a *lesson* only
    // when it's the last keypoint of that lesson (isAllOtherKeypointsCompleted)
    // — the same rule ProgressCubit uses to bump numberOfLessonPassed — so bump
    // by one lesson only then. This lets the ring (and the "done" state on the
    // course's final lesson) advance immediately instead of lagging a network
    // round-trip behind.
    final lessonWillComplete = courseLessonState.isAllOtherKeypointsCompleted;
    final optimisticPassed = passed + (lessonWillComplete ? 1 : 0);
    final optimistic = total > 0 ? (optimisticPassed / total).clamp(0.0, 1.0) : courseProgress;
    return (
      courseId: courseId,
      courseName: displayCourse.title.text,
      courseProgress: courseProgress,
      optimisticProgressAfterKeypoint: optimistic,
      courseImageUrl: displayCourse.image,
      minutes: estimate > 0 ? estimate : _kDefaultLessonMinutes,
    );
  }

  // Design's default of 3 min when a lesson has no BTV-authored estimate.
  static const int _kDefaultLessonMinutes = 3;

  void preloadNextLearningItem() {
    if (state.pageData.items.length <= state.currentLearningItemIndex + 1) return;
    loadLearningItem(state.pageData.items[state.currentLearningItemIndex + 1].id);
  }

  void loadLearningItem(String id, {void Function(LearningItemEntity)? onSuccess}) async {
    await runUseCase<LearningItemEntity>(
      usecase: () => _getLearningItemUseCase(id),
      // buildLoadingState: () => state.copyWith(status: LessonStatus.loading),
      onFailure: (error) {
        emit(state.copyWith(status: LessonStatus.failure, errorMessage: error));
      },
      onSuccess: (item) {
        emit(state.copyWith(status: LessonStatus.success));
        updatePageBreakItem(
          currentPageData: state.pageData,
          updatedItem: item,
          getId: (item) => item.id,
          onSuccess: (pageData) {
            emit(state.copyWith(pageData: pageData));
          },
        );
        onSuccess?.call(item);
      },
    );
  }
}
