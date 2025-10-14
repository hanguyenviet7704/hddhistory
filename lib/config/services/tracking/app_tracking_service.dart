part of '../services.dart';

@LazySingleton(as: ITrackingService)
final class AppTrackingService extends ITrackingService {
  final BaseTrackingService _appTrackingService;
  AppTrackingService(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService);

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
