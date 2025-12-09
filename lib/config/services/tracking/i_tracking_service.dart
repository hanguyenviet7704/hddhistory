part of '../services.dart';

abstract interface class ITrackingService {
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
