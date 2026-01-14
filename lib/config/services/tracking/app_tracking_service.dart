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
  Future<void> trackRoadmapScrView({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required String roadmapSource,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapScrView,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'roadmap_source': roadmapSource,
      },
    );
  }

  @override
  Future<void> trackRoadmapItemClick({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required String itemType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapItemClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'item_type': itemType,
        'item_id': lesson.id,
        'item_name': lesson.trackingName,
      },
    );
  }

  @override
  Future<void> trackHowItWorkScrView({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkScrView,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkDoneClick({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkDoneClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkExitTap({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkExitTap,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
        'source': source,
      },
    );
  }

  @override
  Future<void> trackHowItWorkClick({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
        'source': source,
      },
    );
  }

  @override
  Future<void> trackLessonKeypointScrView({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointScrView,
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
  Future<void> trackLessonKeypointExit({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointExit,
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
  Future<void> trackLessonKeypointClick({
    required SkillsetEntity skillset,
    required CourseEntity course,
    required LessonEntity lesson,
    required KeypointEntity keypoint,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonKeypointClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'course_id': course.id,
        'course_name': course.trackingName,
        'lesson_id': lesson.id,
        'lesson_name': lesson.trackingName,
        'keypoint_id': keypoint.id,
        'keypoint_name': keypoint.trackingName,
      },
    );
  }

  //* Draw events
  @override
  Future<void> trackDrawRoadmapLoginReminder1View(BuildContext context) async {
    _appTrackingService.trackEvent(
      TrackingKey.drawRoadmapLoginReminder1View,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
      },
    );
  }

  @override
  Future<void> trackDrawRoadmapLoginReminder1Click(BuildContext context, bool isClick) async {
    String popupOption = isClick ? 'yes' : 'exit';
    _appTrackingService.trackEvent(
      TrackingKey.drawRoadmapLoginReminder1Click,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
        'popup_option': popupOption,
      },
    );
  }

  @override
  Future<void> trackDrawRoadmapLoginReminder2View(BuildContext context) async {
    _appTrackingService.trackEvent(
      TrackingKey.drawRoadmapLoginReminder2View,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
      },
    );
  }

  @override
  Future<void> trackDrawRoadmapLoginReminder2Click(BuildContext context, bool isClick) async {
    String popupOption = isClick ? 'yes' : 'no';
    _appTrackingService.trackEvent(
      TrackingKey.drawRoadmapLoginReminder2Click,
      parameters: {
        ...TrackingParams.withDrawTopicContext(context),
        'popup_option': popupOption,
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
