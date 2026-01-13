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

  //* Draw events
  Future<void> trackDrawRoadmapLoginReminder1View(BuildContext context);
  Future<void> trackDrawRoadmapLoginReminder1Click(BuildContext context, bool isClick);
  Future<void> trackDrawRoadmapLoginReminder2View(BuildContext context);
  Future<void> trackDrawRoadmapLoginReminder2Click(BuildContext context, bool isClick);

  //* Paywall events
  Future<void> trackPaywallScrView(BuildContext context);
  Future<void> trackPaywallPackageClick(BuildContext context, String packageId);
  Future<void> trackPaywallExitClick(BuildContext context);
  Future<void> trackPaywallStartPremiumClick(BuildContext context, String packageId);
  Future<void> trackPaywallStorePopupDismiss(BuildContext context, String packageId);

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

  //* Feedback events
  Future<void> feedback3ScrView(BuildContext context);
  Future<void> feedback3TagClick(BuildContext context, String tagName, String score);
  Future<void> feedback3SubmitClick(BuildContext context, String feedback, List<String> tags, String score);
  Future<void> feedback3RatingTypeClick(BuildContext context, String ratingType);
  Future<void> feedback3TextClick();
  Future<void> feedback3ExitClick();
}
