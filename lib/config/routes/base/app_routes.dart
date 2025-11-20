part of '../routes.dart';

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

  //* Monetization
  static const String premiumPaywall = '/premium-paywall';

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

  //* Home
  static const String home = '/';


  //* Course
  static const String course = '/course';
  static const String courseRoadmap = '/course-roadmap';
  static const String lessonList = 'lesson-list';
  static const String lessonExplainPopup = 'lesson-explain-popup';

  //? Course - Lesson
  static const String lesson = 'lesson';
  static const String reviewTime = 'review-time';
  static const String lessonComplete = 'lesson-complete';
  static const String keypointComplete = 'keypoint-complete';
  static const String exerciseResultPopup = 'exercise-result-popup';

  //? Course - Roleplay
  static const String roleplayIntro = 'roleplay-intro';
  static const String roleplay = 'roleplay';
  static const String roleplayFeedback = 'roleplay-feedback';
  static const String roleplayComplete = 'roleplay-complete';

  //* Setting
  static const String setting = '/setting';
  static const String profile = 'profile';
  static const String notification = 'notification';
  static const String changeLanguage = 'change-language';
  static const String profileDeleteDialog = 'profile-delete-dialog';
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

  //* Monetization
  static const String premiumPaywall = 'Premium Paywall';

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

  //* Course
  static const String course = 'Course';
  static const String courseRoadmap = 'Course Roadmap';
  static const String lessonList = 'Lesson List';
  static const String lessonExplainPopup = 'Lesson Explain Popup';

  //? Course - Lesson
  static const String lesson = 'Lesson';
  static const String reviewTime = 'Review Time';
  static const String lessonComplete = 'Lesson Complete';
  static const String keypointComplete = 'Keypoint Complete';
  static const String exerciseResultPopup = 'Exercise Result Popup';

  //? Course - Roleplay
  static const String roleplay = 'Roleplay';
  static const String roleplayIntro = 'Roleplay Intro';
  static const String roleplayFeedback = 'Roleplay Feedback';
  static const String roleplayComplete = 'Roleplay Complete';

  //* Setting
  static const String setting = 'Setting';
  static const String profile = 'Profile';
  static const String notification = 'Notification';    
  static const String changeLanguage = 'Change Language';
  static const String profileDeleteDialog = 'Profile Delete Dialog';
}
