part of '../services.dart';

@LazySingleton(as: ITrackingService)
final class AppTrackingService extends ITrackingService {
  final BaseTrackingService _appTrackingService;
  AppTrackingService(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService);


  @override
  Future<void> initialize() async {
    _appTrackingService.initialize();
  }

  @override
  Future<void> trackScreenView(String screenName) async {
    _appTrackingService.trackScreenView(screenName);
  }

  @override
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    _appTrackingService.trackEvent(eventName, parameters: parameters);
  }

  @override
  Future<void> trackError(dynamic exception, {StackTrace? stackTrace, Map<String, dynamic>? context, String? errorType}) async {
    _appTrackingService.trackError(exception, stackTrace: stackTrace, context: context, errorType: errorType);
  }

  @override
  Future<void> trackBreadcrumb(String message, {Map<String, dynamic>? data, String? category}) async {
    _appTrackingService.addBreadcrumb(message, data: data, category: category);
  }

  String _joinTrackingValues(List<String> values) {
    return values.where((value) => value.isNotEmpty).join(',');
  }

  Map<String, dynamic> _courseParams(CourseTrackingData trackingData) {
    return {
      'skill_name': trackingData.skillset.trackingName,
      'skill_id': trackingData.skillset.id,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
    };
  }

  Map<String, dynamic> _courseLessonParams(CourseLessonTrackingData trackingData) {
    return {
      ..._courseParams(trackingData),
      'lesson_id': trackingData.lesson.id,
      'lesson_name': trackingData.lesson.trackingName,
    };
  }

  Map<String, dynamic> _keypointParams(KeypointTrackingData trackingData) {
    return {
      'skill_name': trackingData.skillset.trackingName,
      'skill_id': trackingData.skillset.id,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
      'lesson_id': trackingData.lesson.id,
      'lesson_name': trackingData.lesson.trackingName,
      'keypoint_id': trackingData.keypoint.id,
      'keypoint_name': trackingData.keypoint.trackingName,
    };
  }

  //* Splash & Onboarding events
  @override
  Future<void> trackSplashScrView({String? userId}) async {
    _appTrackingService.trackEvent(
      TrackingKey.splashScrView,
      parameters: {
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
      },
    );
  }

  @override
  Future<void> trackObdIntro1ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro1ScrView);
  }

  @override
  Future<void> trackObdIntro1Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro1Continue);
  }

  @override
  Future<void> trackObdIntro2ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro2ScrView);
  }

  @override
  Future<void> trackObdIntro2Click() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro2Click);
  }

  @override
  Future<void> trackObdLanguagePopupView(String source) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLanguagePopupView,
      parameters: {
        'source': source,
      },
    );
  }

  @override
  Future<void> trackObdLanguageClick(String language) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLanguageClick,
      parameters: {
        'language': language,
      },
    );
  }

  @override
  Future<void> trackObdNameScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameScrView);
  }

  @override
  Future<void> trackObdNameClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameClick);
  }

  @override
  Future<void> trackObdNameContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameContinue);
  }

  @override
  Future<void> trackObdWelcomeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdWelcomeScrView);
  }

  @override
  Future<void> trackObdWelcomeContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdWelcomeContinue);
  }

  @override
  Future<void> trackObdAgeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeScrView);
  }

  @override
  Future<void> trackObdAgeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeClick);
  }

  @override
  Future<void> trackObdAgeContinue(String age) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdAgeContinue,
      parameters: {
        'age': age,
      },
    );
  }

  @override
  Future<void> trackObdAgeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeBack);
  }

  @override
  Future<void> trackObdGenderScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderScrView);
  }

  @override
  Future<void> trackObdGenderClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderClick);
  }

  @override
  Future<void> trackObdGenderContinue(String gender) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdGenderContinue,
      parameters: {
        'gender': gender,
      },
    );
  }

  @override
  Future<void> trackObdGenderBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderBack);
  }

  @override
  Future<void> trackObdLearningGoalScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalScrView);
  }

  @override
  Future<void> trackObdLearningGoalClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalClick);
  }

  @override
  Future<void> trackObdLearningGoalContinue(String learningGoal) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLearningGoalContinue,
      parameters: {
        'learning_goal': learningGoal,
      },
    );
  }

  @override
  Future<void> trackObdLearningGoalBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalBack);
  }

  @override
  Future<void> trackObdSkillsetScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetScrView);
  }

  @override
  Future<void> trackObdSkillsetClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetClick);
  }

  @override
  Future<void> trackObdSkillsetContinue(List<String> skillsets) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdSkillsetContinue,
      parameters: {
        'skillset': _joinTrackingValues(skillsets),
      },
    );
  }

  @override
  Future<void> trackObdSkillsetBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetBack);
  }

  @override
  Future<void> trackObdMotivation1ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation1ScrView);
  }

  @override
  Future<void> trackObdMotivation1Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation1Continue);
  }

  @override
  Future<void> trackObdStrugglesScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesScrView);
  }

  @override
  Future<void> trackObdStrugglesClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesClick);
  }

  @override
  Future<void> trackObdStrugglesContinue(List<String> struggles) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdStrugglesContinue,
      parameters: {
        'struggles': _joinTrackingValues(struggles),
      },
    );
  }

  @override
  Future<void> trackObdStrugglesBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesBack);
  }

  @override
  Future<void> trackObdMotivation2ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation2ScrView);
  }

  @override
  Future<void> trackObdMotivation2Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation2Continue);
  }

  @override
  Future<void> trackObdHowToLearnScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnScrView);
  }

  @override
  Future<void> trackObdHowToLearnSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnSwipe);
  }

  @override
  Future<void> trackObdHowToLearnContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnContinue);
  }

  @override
  Future<void> trackObdHowToLearnBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnBack);
  }

  @override
  Future<void> trackObdFeedbackScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackScrView);
  }

  @override
  Future<void> trackObdFeedbackSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackSwipe);
  }

  @override
  Future<void> trackObdFeedbackContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackContinue);
  }

  @override
  Future<void> trackObdDailyTimeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeScrView);
  }

  @override
  Future<void> trackObdDailyTimeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeClick);
  }

  @override
  Future<void> trackObdDailyTimeContinue(String dailyTime) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdDailyTimeContinue,
      parameters: {
        'daily_time': dailyTime,
      },
    );
  }

  @override
  Future<void> trackObdDailyTimeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeBack);
  }

  @override
  Future<void> trackObdLearningTimeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeScrView);
  }

  @override
  Future<void> trackObdLearningTimeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeClick);
  }

  @override
  Future<void> trackObdLearningTimeContinue(String learningTime) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLearningTimeContinue,
      parameters: {
        'learning_time': learningTime,
      },
    );
  }

  @override
  Future<void> trackObdLearningTimeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeBack);
  }

  @override
  Future<void> trackObdMotivation3ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation3ScrView);
  }

  @override
  Future<void> trackObdMotivation3Click() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation3Click);
  }

  @override
  Future<void> trackObdCompleteScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdCompleteScrView);
  }

  @override
  Future<void> trackObdCompleteClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdCompleteClick);
  }

  //* Home events
  @override
  Future<void> trackHomeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.homeScrView);
  }

  @override
  Future<void> trackHomeTabSwitch(String tabType) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeTabSwitch,
      parameters: {
        'tab_type': tabType,
      },
    );
  }

  @override
  Future<void> trackHomeSkillClick(SkillsetEntity skillset) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeSkillClick,
      parameters: {
        'skill_name': skillset.trackingName,
      },
    );
  }

  @override
  Future<void> trackAllCourseScrView(SkillsetEntity skillset) async {
    _appTrackingService.trackEvent(
      TrackingKey.allCourseScrView,
      parameters: {
        'skill_name': skillset.trackingName,
      },
    );
  }

  @override
  Future<void> trackAllCourseSkillSwitch(SkillsetEntity skillset) async {
    _appTrackingService.trackEvent(
      TrackingKey.allCourseSkillSwitch,
      parameters: {
        'skill_name': skillset.trackingName,
      },
    );
  }

  @override
  Future<void> trackAllCourseCourseClick(SkillsetEntity skillset, CourseEntity course, String source) async {
    _appTrackingService.trackEvent(
      TrackingKey.allCourseCourseClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'course_id': course.id,
        'source': source,
      },
    );
  }

  @override
  Future<void> trackAllCourseFirstCourseClick(SkillsetEntity skillset, CourseEntity course) async {
    _appTrackingService.trackEvent(
      TrackingKey.allCourseFirstCourseClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'course_id': course.id,
      },
    );
  }

  @override
  Future<void> trackAllCourseExit(String source) async {
    _appTrackingService.trackEvent(
      TrackingKey.allCourseExit,
      parameters: {
        'source': source,
      },
    );
  }

  @override
  Future<void> trackPopupLearningIntroScrView(CourseEntity course) async {
    final courseName = course.trackingNameOrText;
    _appTrackingService.trackEvent(
      TrackingKey.popupLearningIntroScrView,
      parameters: {
        'course_id': course.id,
        'course_name': courseName,
      },
    );
  }

  @override
  Future<void> trackPopupLearningIntroContinue() async {
    _appTrackingService.trackEvent(TrackingKey.popupLearningIntroContinue);
  }

  @override
  Future<void> trackPopupLearningIntroSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.popupLearningIntroSwipe);
  }

  @override
  Future<void> trackRoadmapScrView(
    CourseTrackingData trackingData, {
    required String roadmapSource,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapScrView,
      parameters: {
        ..._courseParams(trackingData),
        'roadmap_source': roadmapSource,
      },
    );
  }

  @override
  Future<void> trackRoadmapItemClick(
    CourseLessonTrackingData trackingData, {
    required String itemType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapItemClick,
      parameters: {
        ..._courseParams(trackingData),
        'item_type': itemType,
        'item_id': trackingData.lesson.id,
        'item_name': trackingData.lesson.trackingName,
      },
    );
  }

  @override
  Future<void> trackHowItWorkScrView(
    CourseLessonTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkScrView,
      parameters: {
        ..._courseLessonParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkDoneClick(
    CourseLessonTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkDoneClick,
      parameters: {
        ..._courseLessonParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkExitTap(
    CourseLessonTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkExitTap,
      parameters: {
        ..._courseLessonParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkClick(
    CourseLessonTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkClick,
      parameters: {
        ..._courseLessonParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackLessonKeypointScrView(CourseLessonTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointScrView,
      parameters: _courseLessonParams(trackingData),
    );
  }

  @override
  Future<void> trackLessonKeypointExit(CourseLessonTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointExit,
      parameters: _courseLessonParams(trackingData),
    );
  }

  @override
  Future<void> trackLessonKeypointClick(
    CourseLessonTrackingData trackingData, {
    required KeypointEntity keypoint,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointClick,
      parameters: {
        ..._courseLessonParams(trackingData),
        'keypoint_id': keypoint.id,
        'keypoint_name': keypoint.trackingName,
      },
    );
  }

  //* Keypoint events
  @override
  Future<void> trackKeypointTheoryScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointTheoryScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointTheoryContinueClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointTheoryContinueClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseMultiClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseMultiClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseDrag(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseDrag,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseArrange(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseArrange,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordAnswer(
    KeypointTrackingData trackingData, {
    required String answerType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordAnswer,
      parameters: {
        ..._keypointParams(trackingData),
        'answer_type': answerType,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordTyping(
    KeypointTrackingData trackingData, {
    required String typingInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordTyping,
      parameters: {
        ..._keypointParams(trackingData),
        'typing_interaction': typingInteraction,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordVoice(
    KeypointTrackingData trackingData, {
    required String recordInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordVoice,
      parameters: {
        ..._keypointParams(trackingData),
        'record_interaction': recordInteraction,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseCheckClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseCheckClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseResultView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseResultView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainReplay(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainReplay,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseScroll(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseScroll,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseContinue(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseContinue,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainClose(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainClose,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointFinishScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointFinishScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackLessonFinishScrView({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonFinishScrView,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
      },
    );
  }

  @override
  Future<void> trackKeypointExitClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExitPopupView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitPopupView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExitPopupClick(
    KeypointTrackingData trackingData, {
    required String option,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitPopupClick,
      parameters: {
        ..._keypointParams(trackingData),
        'popup_option': option,
      },
    );
  }

  //* Paywall events
  @override
  Future<void> trackPaywallScrView(BuildContext context) async {
    _appTrackingService.trackEvent(
      TrackingKey.paywallScrView,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
        ...TrackingParams.withPaywallSource(context),
      },
    );
  }

  @override
  Future<void> trackPaywallPackageClick(BuildContext context, String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.paywallPackageClick,
      parameters: {
        'package': packageId,
        ...TrackingParams.withDrawTopicContext(context),
        ...TrackingParams.withPaywallSource(context),
      },
    );
  }

  @override
  Future<void> trackPaywallExitClick(BuildContext context) async {
    _appTrackingService.trackEvent(
      TrackingKey.paywallExitClick,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
        ...TrackingParams.withPaywallSource(context),
      },
    );
  }

  @override
  Future<void> trackPaywallStartPremiumClick(BuildContext context, String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.paywallStartPremiumClick,
      parameters: {
        'package': packageId,
        ...TrackingParams.withDrawTopicContext(context),
        ...TrackingParams.withPaywallSource(context),
      },
    );
  }

  @override
  Future<void> trackPaywallStorePopupDismiss(BuildContext context, String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.paywallStorePopupDismiss,
      parameters: {
        'package': packageId,
        ...TrackingParams.withDrawTopicContext(context),
        ...TrackingParams.withPaywallSource(context),
      },
    );
  }


  //* Subscription events
  @override
  Future<void> trackSubscriptionRenewed(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionRenewed,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionCancelled(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionCancelled,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionExpired(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionExpired,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionFailed(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionFailed,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionCompleted(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionCompleted,
      parameters: {
        'package': packageId,
      },
    );
  }

  //* Profile events
  @override
  Future<void> trackProfileView() async {
    _appTrackingService.trackEvent(TrackingKey.profileView);
  }

  @override
  Future<void> trackProfileLanguageView() async {
    _appTrackingService.trackEvent(TrackingKey.profileLanguageView);
  }

  @override
  Future<void> trackProfileLanguageSelect(String language) async {
    _appTrackingService.trackEvent(TrackingKey.profileLanguageSelect, parameters: {'language': language});
  }

  @override
  Future<void> trackProfileSignoutClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileSignoutClick);
  }

  @override
  Future<void> trackProfileUpgradeClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileUpgradeClick);
  }

  @override
  Future<void> trackProfileSettingClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileSettingClick);
  }

  //* Feedback events
  @override
  Future<void> feedback3ScrView(BuildContext context) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3ScrView,
      parameters: {
        ...TrackingParams.withDrawTopic(),
        ...TrackingParams.trackingUserState(context),
      },
    );
  }

  @override
  Future<void> feedback3TagClick(BuildContext context, String tagName, String score) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3TagClick,
      parameters: {
        'tag_name': tagName,
        'score': score,
        ...TrackingParams.withDrawTopic(),
        ...TrackingParams.trackingUserState(context),
      },
    );
  }

  @override
  Future<void> feedback3SubmitClick(BuildContext context, String feedback, List<String> tagSelected, String score) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3SubmitClick,
      parameters: {
        ...TrackingParams.withDrawTopic(),
        'tag_selected': tagSelected,
        'feedback_content': feedback,
        'score': score,
        ...TrackingParams.trackingUserState(context),
      },
    );
  }

  @override
  Future<void> feedback3RatingTypeClick(BuildContext context, String ratingType) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3RatingTypeClick,
      parameters: {
        ...TrackingParams.withDrawTopic(),
        'score': ratingType,
        ...TrackingParams.trackingUserState(context),
      },
    );
  }

  @override
  Future<void> feedback3TextClick() async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3TextClick,
      parameters: TrackingParams.withDrawTopic(),
    );
  }

  @override
  Future<void> feedback3ExitClick() async {
    _appTrackingService.trackEvent(
      TrackingKey.feedback3Exit,
      parameters: TrackingParams.withDrawTopic(),
    );
  }
}
