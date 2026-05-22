part of '../services.dart';

abstract interface class ITrackingService {
  //* Base events - reused for all projects
  Future<void> initialize();
  Future<void> trackScreenView(String screenName);
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters});
  Future<void> trackError(dynamic exception, {StackTrace? stackTrace, Map<String, dynamic>? context, String? errorType});
  Future<void> trackBreadcrumb(String message, {Map<String, dynamic>? data, String? category});

  //* Splash & Onboarding events
  Future<void> trackSplashScrView({String? userId});
  Future<void> trackObdIntro1ScrView();
  Future<void> trackObdIntro1Continue();
  Future<void> trackObdIntro2ScrView();
  Future<void> trackObdIntro2Click();
  Future<void> trackObdLanguagePopupView(String source);
  Future<void> trackObdLanguageClick(String language);
  Future<void> trackObdNameScrView();
  Future<void> trackObdNameClick();
  Future<void> trackObdNameContinue();
  Future<void> trackObdWelcomeScrView();
  Future<void> trackObdWelcomeContinue();
  Future<void> trackObdAgeScrView();
  Future<void> trackObdAgeClick();
  Future<void> trackObdAgeContinue(String age);
  Future<void> trackObdAgeBack();
  Future<void> trackObdGenderScrView();
  Future<void> trackObdGenderClick();
  Future<void> trackObdGenderContinue(String gender);
  Future<void> trackObdGenderBack();
  Future<void> trackObdLearningGoalScrView();
  Future<void> trackObdLearningGoalClick();
  Future<void> trackObdLearningGoalContinue(String learningGoal);
  Future<void> trackObdLearningGoalBack();
  Future<void> trackObdSkillsetScrView();
  Future<void> trackObdSkillsetClick();
  Future<void> trackObdSkillsetContinue(List<String> skillsets);
  Future<void> trackObdSkillsetBack();
  Future<void> trackObdMotivation1ScrView();
  Future<void> trackObdMotivation1Continue();
  Future<void> trackObdStrugglesScrView();
  Future<void> trackObdStrugglesClick();
  Future<void> trackObdStrugglesContinue(List<String> struggles);
  Future<void> trackObdStrugglesBack();
  Future<void> trackObdMotivation2ScrView();
  Future<void> trackObdMotivation2Continue();
  Future<void> trackObdHowToLearnScrView();
  Future<void> trackObdHowToLearnSwipe();
  Future<void> trackObdHowToLearnContinue();
  Future<void> trackObdHowToLearnBack();
  Future<void> trackObdFeedbackScrView();
  Future<void> trackObdFeedbackSwipe();
  Future<void> trackObdFeedbackContinue();
  Future<void> trackObdDailyTimeScrView();
  Future<void> trackObdDailyTimeClick();
  Future<void> trackObdDailyTimeContinue(String dailyTime);
  Future<void> trackObdDailyTimeBack();
  Future<void> trackObdLearningTimeScrView();
  Future<void> trackObdLearningTimeClick();
  Future<void> trackObdLearningTimeContinue(String learningTime);
  Future<void> trackObdLearningTimeBack();
  Future<void> trackObdMotivation3ScrView();
  Future<void> trackObdMotivation3Click();
  Future<void> trackObdCompleteScrView();
  Future<void> trackObdCompleteClick();
  Future<void> trackObdNotificationGateView();
  Future<void> trackObdNotificationNotifyMeClick();
  Future<void> trackObdNotificationMaybeLaterClick();

  //* Home events
  Future<void> trackHomeScrView();
  Future<void> trackHomeTabSwitch(String tabType);
  Future<void> trackHomeSkillClick(SkillsetEntity skillset);
  Future<void> trackHomeStreakChipClick({required int currentStreak});
  Future<void> trackHomeStreakPopupView({required int currentStreak});
  Future<void> trackHomeStreakPopupClose({required int currentStreak});
  Future<void> trackInAppSurveyEntryView({required String source});
  Future<void> trackInAppSurveyEntryClick({required String source});
  Future<void> trackInAppSurveyPopupView({required String source, required String step});
  Future<void> trackInAppSurveyPopupClose({required String source, required String step});
  Future<void> trackInAppSurveyEmojiClick({required String source, required String branchId, required int branchIndex});
  Future<void> trackInAppSurveyClosedQuestionView({required String source, required String branchId, required int branchIndex});
  Future<void> trackInAppSurveyClosedOptionClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  });
  Future<void> trackInAppSurveyClosedContinueClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  });
  Future<void> trackInAppSurveyOpenQuestionView({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  });
  Future<void> trackInAppSurveySendClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
  });
  Future<void> trackInAppSurveySendSuccess({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
  });
  Future<void> trackInAppSurveySendFailure({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
    required String errorType,
  });

  //* Course selection events
  Future<void> trackCourseSelectAllCourseView({required String source});
  Future<void> trackCourseSelectMyCourseView({required String source});
  Future<void> trackCourseSelectCategorySlide();
  Future<void> trackCourseSelectCategoryClick(SkillsetEntity skillset, {required bool isRightDirection});
  Future<void> trackCourseSelectFirstCourseClick(SkillsetEntity skillset, CourseEntity course);
  Future<void> trackCourseSelectCourseClick(
    SkillsetEntity skillset,
    CourseEntity course, {
    required String source,
  });
  Future<void> trackCourseSelectExit();
  Future<void> trackCourseSelectAllCourseScroll({required bool isSameCategory});

  //* Course events
  Future<void> trackPopupLearningIntroScrView(CourseEntity course);
  Future<void> trackPopupLearningIntroContinue();
  Future<void> trackPopupLearningIntroSwipe();
  Future<void> trackRoadmapScrView(
    CourseTrackingData trackingData, {
    required String roadmapSource,
  });
  Future<void> trackRoadmapItemClick(
    CourseLessonTrackingData trackingData, {
    required String itemType,
  });
  Future<void> trackPopupItemImp(CourseLessonTrackingData trackingData);
  Future<void> trackPopupItemClick(CourseLessonTrackingData trackingData);
  Future<void> trackRoadmapItemScroll(CourseTrackingData trackingData);
  Future<void> trackRoadmapQuickLearningClick(
    CourseTrackingData trackingData, {
    required String actionType,
  });
  Future<void> trackHowItWorkScrView(
    CourseLessonTrackingData trackingData, {
    required String source,
  });
  Future<void> trackOutputPracticePopupView(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  });
  Future<void> trackOutputPracticePopupClose(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  });
  Future<void> trackOutputPracticeStartClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  });
  Future<void> trackOutputPracticeScrView(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required String language,
    required String entryState,
  });
  Future<void> trackOutputPracticeOptionClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required String optionLabel,
    required int optionValue,
    required String inputSource,
  });
  Future<void> trackOutputPracticeSendClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required int messageLength,
  });
  Future<void> trackOutputPracticeExitClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
  });
  Future<void> trackVideoLessonPopupView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonPopupClose(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonStartClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonScrView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonExitClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int videoPosition,
  });
  Future<void> trackVideoLessonPlayClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonPauseClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int videoPosition,
  });
  Future<void> trackVideoLessonSeek(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int seekFromSecond,
    required int seekToSecond,
    int? seekLatencyMs,
  });
  Future<void> trackVideoLessonPlayerInit(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String initStatus,
    required String warmupState,
    int? timeToFirstFrameMs,
  });
  Future<void> trackVideoLessonNotesView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonAddNoteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteMode,
    required int atSecond,
  });
  Future<void> trackVideoLessonNoteSaveClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteMode,
    String? noteId,
    required int atSecond,
  });
  Future<void> trackVideoLessonNoteEditClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteId,
    required String noteMode,
  });
  Future<void> trackVideoLessonNoteDeleteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteId,
  });
  Future<void> trackVideoLessonSummaryView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonSummaryScroll(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonSummaryClose(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonShareClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonQuizView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
  });
  Future<void> trackVideoLessonQuizCheck(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  });
  Future<void> trackVideoLessonQuizResultView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  });
  Future<void> trackVideoLessonQuizContinue(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  });
  Future<void> trackVideoLessonCompleteView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });
  Future<void> trackVideoLessonMarkCompleteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  });

  //* Keypoint audio events
  Future<void> trackKeypointAudioPopupView(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioPopupReadClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioPopupListenClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioPopupExitClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioScreenView(
    KeypointTrackingData trackingData, {
    required String mode,
  });
  Future<void> trackKeypointAudioModeSwitch(
    KeypointTrackingData trackingData, {
    required String mode,
    required String entryPoint,
    int? audioPosition,
  });
  Future<void> trackKeypointAudioPlayClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioPauseClick(
    KeypointTrackingData trackingData, {
    required int audioPosition,
  });
  Future<void> trackKeypointAudioExitClick(
    KeypointTrackingData trackingData, {
    required int audioPosition,
  });
  Future<void> trackKeypointAudioSeekBackClick(
    KeypointTrackingData trackingData, {
    required int seekFromSecond,
    required int seekToSecond,
  });
  Future<void> trackKeypointAudioSeekForwardClick(
    KeypointTrackingData trackingData, {
    required int seekFromSecond,
    required int seekToSecond,
  });
  Future<void> trackKeypointAudioSpeedOpen(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioSpeedSelect(
    KeypointTrackingData trackingData, {
    required double speed,
  });
  Future<void> trackKeypointAudioCompleteView(KeypointTrackingData trackingData);
  Future<void> trackKeypointAudioCompleteContinueClick(KeypointTrackingData trackingData);

  //* Keypoint events
  Future<void> trackKeypointTheoryScroll(KeypointTrackingData trackingData);
  Future<void> trackKeypointTheoryScrView(KeypointTrackingData trackingData);
  Future<void> trackKeypointTheoryContinueClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseScrView(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseMultiClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseDrag(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseArrange(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseRecordAnswer(
    KeypointTrackingData trackingData, {
    required String answerType,
  });
  Future<void> trackKeypointExerciseRecordTyping(
    KeypointTrackingData trackingData, {
    required String typingInteraction,
  });
  Future<void> trackKeypointExerciseRecordVoice(
    KeypointTrackingData trackingData, {
    required String recordInteraction,
  });
  Future<void> trackKeypointExerciseCheckClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseResultView(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseExplainClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseExplainView(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseExplainReplay(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseScroll(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseContinue(KeypointTrackingData trackingData);
  Future<void> trackKeypointExerciseExplainClose(KeypointTrackingData trackingData);
  Future<void> trackKeypointFinishScrView(KeypointTrackingData trackingData);
  Future<void> trackKeypointBadgeUpdateScrView(KeypointTrackingData trackingData);
  Future<void> trackKeypointFinishComplete(KeypointTrackingData trackingData);
  Future<void> trackLessonFinishScrView(CourseLessonTrackingData trackingData);
  Future<void> trackKeypointExitClick(KeypointTrackingData trackingData);
  Future<void> trackKeypointExitPopupView(KeypointTrackingData trackingData);
  Future<void> trackKeypointExitPopupClick(
    KeypointTrackingData trackingData, {
    required String option,
  });
  Future<void> trackKeypointPopupNavView(KeypointTrackingData trackingData);
  Future<void> trackKeypointPopupNavContinue(KeypointTrackingData trackingData);
  Future<void> trackCompletionStreakSuccessView({
    required String variant,
    required int currentStreak,
  });
  Future<void> trackCompletionStreakSuccessCommitClick({
    required String variant,
    required int currentStreak,
  });

  //* Roleplay events
  Future<void> trackRoleplayInfoScrView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayInfoContinueClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayOverviewExitClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayOverviewScroll(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayMissionsView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayMissionsScroll(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayStartClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayConvScrView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayConvExitClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayConvScroll(
    RoleplayTrackingData trackingData, {
    required String haveQuiz,
  });
  Future<void> trackRoleplayVoiceInteraction(
    RoleplayTrackingData trackingData, {
    required String voiceAction,
  });
  Future<void> trackRoleplayQuizImp(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizExpandedView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizExpandedClose(
    RoleplayTrackingData trackingData, {
    required String interactType,
  });
  Future<void> trackRoleplayQuizSingSelect(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizMultiSelect(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizDrag(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizArrange(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizRecordAns(
    RoleplayTrackingData trackingData, {
    required String answerType,
  });
  Future<void> trackRoleplayQuizRecordTyping(
    RoleplayTrackingData trackingData, {
    required String typingInteraction,
  });
  Future<void> trackRoleplayQuizRecordVoice(
    RoleplayTrackingData trackingData, {
    required String recordInteraction,
  });
  Future<void> trackRoleplayQuizCheck(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizResultView(
    RoleplayTrackingData trackingData, {
    required String source,
  });
  Future<void> trackRoleplayQuizResultScroll(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizContinue(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizReviewReplay(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizCollapsedClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayQuizCollapsedReplay(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayCompleteClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayDoneScrView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayDoneResultClick(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayResultScrView(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayResultScroll(RoleplayTrackingData trackingData);
  Future<void> trackRoleplayResultContinue(RoleplayTrackingData trackingData);
  Future<void> trackBadgeCompleteScrView({RoleplayTrackingData? trackingData});

  //* Feedback events
  Future<void> trackFeedbackCompleteLessonView(
    CourseTrackingData trackingData, {
    required String source,
  });
  Future<void> trackFeedbackCompleteLessonSend(
    CourseTrackingData trackingData, {
    required String source,
  });
  Future<void> trackFeedbackIncompleteLessonView(
    CourseTrackingData trackingData, {
    required String source,
  });
  Future<void> trackFeedbackIncompleteLessonSend(
    CourseTrackingData trackingData, {
    required String source,
  });

  //* Subscription events
  Future<void> trackSubscriptionRenewed(String packageId);
  Future<void> trackSubscriptionCancelled(String packageId);
  Future<void> trackSubscriptionExpired(String packageId);
  Future<void> trackSubscriptionFailed(String packageId);
  Future<void> trackSubscriptionCompleted(String packageId);

  //* Profile events
  Future<void> trackProfileView();
  Future<void> trackProfileLanguageView();
  Future<void> trackProfileLanguageSelect(String language);
  Future<void> trackProfileSignoutClick();
  Future<void> trackProfileUpgradeClick();
  Future<void> trackProfileSettingClick();

  //* Setting events
  Future<void> trackSettingScrView();
  Future<void> trackSettingScroll();
  Future<void> trackSettingProfileClick();
  Future<void> trackSettingProfileEditClick();
  Future<void> trackSettingProfileDoneClick();
  Future<void> trackSettingProfileDeleteClick();
  Future<void> trackProfileDeleteScrView();
  Future<void> trackProfileDeleteOptionClick(String value);
  Future<void> trackSettingDetailClick();
  Future<void> trackSettingDetailScrView();
  Future<void> trackSettingLanguageClick();
  Future<void> trackSettingLanguageScrView(String language);
  Future<void> trackSettingTermClick();
  Future<void> trackSettingRestorePurchClick();
  Future<void> trackSettingLogoutClick();
  Future<void> trackSettingPremiumClick();
  Future<void> trackSettingNotificationToggleOn();
  Future<void> trackSettingNotificationToggleOff();
  Future<void> trackPremiumScrView();
  Future<void> trackPremiumScroll();
  Future<void> trackPremiumInforSwipe();
  Future<void> trackPremiumRestoreClick();
  Future<void> trackPremiumPurchase();
  Future<void> trackPremiumScrExit();
  Future<void> trackPremiumAllpackClick();
  Future<void> trackPremiumAllpackScrView();
  Future<void> trackPremiumAllpackPick(String premiumId);
  Future<void> trackPremiumAllpackPurchase();
  Future<void> trackSettingBadgeClick(CourseTrackingData trackingData);
  Future<void> trackSettingBadgeSlide(CourseTrackingData trackingData);
  Future<void> trackSettingBadgeDetailView(CourseTrackingData trackingData);
  Future<void> trackSettingBadgeDetailSlide(CourseTrackingData trackingData);
  Future<void> trackSettingBadgeGoCourse(CourseTrackingData trackingData);
}
