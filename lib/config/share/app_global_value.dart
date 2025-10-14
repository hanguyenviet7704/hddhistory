part of 'share.dart';

mixin AppGlobalValue {
  static Size get uiSize => MediaQuery.sizeOf(AppConfig.instance.context!);
  static int affiliateId = 0;
  static const Size designSize = Size(1440, 960);
  static ThemeData appTheme = ThemeData();
  static String accessToken = '';
  static String refreshToken = '';
  static String firebaseToken = '';
  static bool isGuest = false;

  static bool get isGuestOrNotLogin => isGuest || accessToken.isEmpty;
}
