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
  static const String intro = '/intro';

  //* Auth
  static const String login = '/login';
  static const String register = '/register';
  static const String registerAuth = '/register-auth';
  static const String forgotPassword = 'forgot-password';
  static const String otp = 'otp';
  static const String setupPassword = 'setup-password';
  static const String noAuth = '/no-auth';
  static const String changePassword = 'change-password';

  //* Home - Road Map
  static const String home = '/';
  static const String choosePath = '/choose-path';

  //* Picture Study
  static const String pictureStudy = 'picture-study';
  static const String galleryView = 'gallery-view';
  static const String galleryPictureView = 'gallery-picture-view';
  static const String colorPickerLesson = 'color-picker-lesson';
  static const String colorPickerLessonResult = 'color-picker-lesson-result';
  static const String pictureColorPicker = '/picture-color-picker';
  static const String lessonCompleteResult = '/lesson-complete-result';
  static const String miniQuizz = '/mini-quizz';

  //* Draw
  static const String draw = '/draw';
  static const String previewLecture = '/preview-lecture';

  //* Drawing Result
  static const String drawingResult = '/drawing-result';

  //* Lesson Story
  static const String lessonStory = '/lesson-story';
  static const String reward = '/reward';

  //* Monetization
  static const String premiumPaywall = '/premium-paywall';
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
  static const String intro = 'Intro Page';

  //* Auth
  static const String login = 'Login Page';
  static const String register = 'Register Page';
  static const String registerAuth = 'Register Auth Page';
  static const String forgotPassword = 'Forgot Password Page';
  static const String otp = 'OTP Page';
  static const String setupPassword = 'Setup Password Page';
  static const String noAuth = 'No Auth Page';
  static const String changePassword = 'Change Password Page';

  //* Home - Road Map
  static const String home = 'Home';
  static const String choosePath = 'Choose Path';

  //* Picture Study
  static const String pictureStudy = 'Picture Study';
  static const String galleryView = 'Gallery View';
  static const String galleryPictureView = 'Gallery Picture View';
  static const String colorPickerLesson = 'Color Picker Lesson';
  static const String colorPickerLessonResult = 'Color Picker Lesson Result';
  static const String pictureColorPicker = 'Picture Color Picker';
  static const String lessonCompleteResult = 'Lesson Complete Result';
  static const String miniQuizz = 'Mini Quizz';

  //* Canvas
  static const String canvas = 'Canvas';

  //* Draw
  static const String draw = 'Draw Page';

  //* Drawing Result
  static const String drawingResult = 'Drawing Result';

  //* Lesson Story
  static const String lessonStory = 'Lesson Story';
  static const String reward = 'Reward';

  //* Monetization
  static const String premiumPaywall = 'Premium Paywall';

  static const String preivewLecture = 'Preview Lecture';


}
