part of 'routes.dart';

mixin RoutePath {
  //* General
  static const String back = '/..';
  static const String webView = '/web-view';
  static const String imageView = '/image-view';
  static const String shellRoute = '/shell-route';
  static const String noInternetConnection = '/no-internet-connection';
  static const String commingSoon = '/comming-soon';

  //* Splash
  static const String splash = '/splash';
  static const String chooseLanguage = '/choose-language';
  static const String intro = '/intro';
  static const String noAuth = '/no-auth';

  //* Onboard
  static const String onboard = '/onboard';
  static const String dataCollect = '/data-collect';
  static const String dataCollectMotivationStep = '/data-collect-motivation-step';
  static const String dataCollectSummary = '/data-collect-summary';

  //* Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String registerAuth = '/register-auth';
  static const String forgotPassword = 'forgot-password';
  static const String otp = 'otp';
  static const String setupPassword = 'setup-password';
  static const String changePassword = 'change-password';

  //* Home - Road Map
  static const String home = '/';

  //* Monetization
  static const String premiumPaywall = '/premium-paywall';

  //* Exercise
  static const String theory = '/theory';
  static const String exercise = '/exercise';
  static const String lessonComplete = '/lesson-complete';
  static const String exerciseResultPopup = '/exercise-result-popup';
}

mixin RouteNamed {
  //* General
  static const String back = 'Back';
  static const String webView = 'Web View';
  static const String imageView = 'Image View';
  static const String shellRoute = 'Shell Route';
  static const String noInternetConnection = 'No Internet Connection';
  static const String commingSoon = 'Comming Soon';

  //* Splash Screen
  static const String splash = 'Splash Page';
  static const String chooseLanguage = 'Choose Language Page';
  static const String intro = 'Intro Page';
  static const String noAuth = 'No Auth Page';

  //* Onboard
  static const String onboard = 'Onboard Page';
  static const String dataCollect = 'Data Collect Page';
  static const String dataCollectMotivationStep = 'Data Collect Motivation Step Page';
  static const String dataCollectSummary = 'Data Collect Summary Page';

  //* Auth
  static const String login = 'Login Page';
  static const String register = 'Register Page';
  static const String registerAuth = 'Register Auth Page';
  static const String forgotPassword = 'Forgot Password Page';
  static const String otp = 'OTP Page';
  static const String setupPassword = 'Setup Password Page';
  static const String changePassword = 'Change Password Page';

  //* Home - Road Map
  static const String home = 'Home';

  //* Monetization
  static const String premiumPaywall = 'Premium Paywall';

  //* Exercise
  static const String exercise = 'Exercise';
  static const String theory = 'Theory';
  static const String lessonComplete = 'Lesson Complete';
  static const String exerciseResultPopup = 'Exercise Result Popup';
}
