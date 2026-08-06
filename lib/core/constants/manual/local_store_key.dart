part of '../constants.dart';

class LocalStoreKey {
  static const String accessToken = "ACCESS_TOKEN";
  static const String refreshToken = "REFRESH_TOKEN";
  static const String userPassFirstTime = "USER_PASS_FIRST_TIME";
  static const String localUserType = "LOCAL_USER_TYPE";
  static const String localUser = "LOCAL_USER";
  static const String localDriver = "LOCAL_DRIVER";
  static const String uid = "APP_UID";
  static const String language = "LANG";
  static const String openedApp = "OPENED_APP";
  static const String authkey = "APP_AUTH_KEY";
  static const String deviceTokenUID = "DEVICE_TOKEN_UID";
  static const String notificationAppPreferenceEnabled = "NOTIFICATION_APP_PREFERENCE_ENABLED";
  // Pending tracking events waiting to be flushed to meup-api. Persisted so a
  // kill / offline stretch doesn't lose the behaviour trail.
  static const String trackingEventQueue = "TRACKING_EVENT_QUEUE";
}
