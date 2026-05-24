part of '../../daily_warm_up.dart';

extension DailyWarmUpCubitTracking on DailyWarmUpCubit {
  Future<void> trackDailyWarmUpEntryCheck({required String source, required String shownDate}) {
    return AppService.instance.appTrackingService.trackDailyWarmUpEntryCheck(source: source, shownDate: shownDate);
  }

  Future<void> trackDailyWarmUpSkip({required String source, required String skipReason}) {
    return AppService.instance.appTrackingService.trackDailyWarmUpSkip(source: source, skipReason: skipReason);
  }

  Future<void> trackDailyWarmUpP1View() {
    final entity = state.entity;
    if (entity == null) return Future.value();
    return AppService.instance.appTrackingService.trackDailyWarmUpP1View(
      source: 'home_open',
      courseId: entity.courseId,
      suggestedCourseId: entity.suggestedCourseId,
      lessonId: entity.lessonId,
      keypointId: entity.keypointId,
      shownDate: state.shownDate,
    );
  }

  Future<void> trackDailyWarmUpStartClick() {
    final entity = state.entity;
    if (entity == null) return Future.value();
    return AppService.instance.appTrackingService.trackDailyWarmUpStartClick(
      source: 'home_open',
      courseId: entity.courseId,
      suggestedCourseId: entity.suggestedCourseId,
      lessonId: entity.lessonId,
      keypointId: entity.keypointId,
      shownDate: state.shownDate,
    );
  }

  Future<void> trackDailyWarmUpMaybeLaterClick() {
    final entity = state.entity;
    if (entity == null) return Future.value();
    return AppService.instance.appTrackingService.trackDailyWarmUpMaybeLaterClick(
      source: 'home_open',
      courseId: entity.courseId,
      suggestedCourseId: entity.suggestedCourseId,
      lessonId: entity.lessonId,
      keypointId: entity.keypointId,
      shownDate: state.shownDate,
    );
  }

  Future<void> trackCurrentQuestionView() {
    final question = state.currentQuestion;
    if (question == null) return Future.value();
    return AppService.instance.appTrackingService.trackDailyWarmUpQuestionView(
      questionId: question.id.toString(),
      questionIndex: state.currentQuestionIndex,
      questionType: dailyWarmUpQuestionTypeName(question),
      questionForm: question.form.rawValue,
    );
  }

  Future<void> trackDailyWarmUpQuestionCheckClick(QuestionEntity question) {
    return AppService.instance.appTrackingService.trackDailyWarmUpQuestionCheckClick(
      questionId: question.id.toString(),
      questionIndex: state.currentQuestionIndex,
      questionType: dailyWarmUpQuestionTypeName(question),
      questionForm: question.form.rawValue,
    );
  }

  Future<void> trackDailyWarmUpQuestionResultView(DailyWarmUpAnswerResultEntity result) {
    return AppService.instance.appTrackingService.trackDailyWarmUpQuestionResultView(
      questionId: result.questionId.toString(),
      questionIndex: result.questionIndex,
      questionType: dailyWarmUpQuestionTypeName(state.usableQuestions[result.questionIndex]),
      questionForm: result.questionForm.rawValue,
      isCorrect: result.isCorrect,
      resultType: result.type.trackingName,
    );
  }

  Future<void> trackDailyWarmUpQuestionContinueClick(DailyWarmUpAnswerResultEntity result) {
    return AppService.instance.appTrackingService.trackDailyWarmUpQuestionContinueClick(
      questionId: result.questionId.toString(),
      questionIndex: result.questionIndex,
    );
  }

  Future<void> trackDailyWarmUpExitClick() {
    return AppService.instance.appTrackingService.trackDailyWarmUpExitClick(
      questionIndex: state.currentQuestionIndex,
      answeredCount: state.answeredCount,
    );
  }

  Future<void> trackDailyWarmUpCompleteView() {
    return AppService.instance.appTrackingService.trackDailyWarmUpCompleteView(
      answeredCount: state.answeredCount,
      correctCount: state.correctCount,
      suggestedCourseId: state.entity?.suggestedCourseId ?? '',
    );
  }

  Future<void> trackDailyWarmUpStartLessonClick() {
    return AppService.instance.appTrackingService.trackDailyWarmUpStartLessonClick(
      suggestedCourseId: state.entity?.suggestedCourseId ?? '',
    );
  }

  Future<void> trackDailyWarmUpExploreMoreClick() {
    return AppService.instance.appTrackingService.trackDailyWarmUpExploreMoreClick(
      suggestedCourseId: state.entity?.suggestedCourseId ?? '',
    );
  }

  Future<void> trackDailyWarmUpRouteFailure({required String failureStage}) {
    return AppService.instance.appTrackingService.trackDailyWarmUpRouteFailure(
      suggestedCourseId: state.entity?.suggestedCourseId ?? '',
      failureStage: failureStage,
    );
  }
}
