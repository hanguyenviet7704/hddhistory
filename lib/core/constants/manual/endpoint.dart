part of '../constants.dart';

mixin AppEndpoint {
  //* GraphQL
  static const String graphql = '/graphql';

  //* Auth
  static const String login = '/api/v1/users/login';
  static const String loginAnonymous = '/api/v1/users/anonymous';
  static const String loginProvider = '/api/v1/users/login/provider';
  static const String register = '/api/v1/users/register';
  static const String logout = '/api/v1/users/logout';
  static const String forgotPassword = '/api/v1/users/forgot-password';
  static const String resetPassword = '/api/v1/users/reset-password';
  static const String resendOTP = '/resend-otp';
  static const String verifyOTP = '/api/v1/users/verify-otp';
  static const String updatePassword = '/api/v1/users/update-password';
  static const String deletePermanentUser = '/api/v1/users/delete-permanently-user';
  static const String deleteAccount = '/api/v1/users/delete-my-account';
  static const String changeProfileId = '/rest/v1/rpc/p_change_user_profile_id';

  //* Config
  static const String config = '/config';
  static const String appName = '/config/app-name';
  static const String splash = '/config/splashes';
  static const String termsOfUseApp = '/config/terms-of-use-app';
  static const String termsOfSalePolicy = '/config/terms-of-sale-policy';
  static const String privacyPolicy = '/config/privacy-policy';

  //* Users API
  static const String usersRegister = '/api/v1/users/register';
  static const String usersAnonymous = '/api/v1/users/anonymous';
  static const String usersLogin = '/api/v1/users/login';
  static const String usersLogout = '/api/v1/users/logout';
  static const String usersLoginProvider = '/api/v1/users/login/provider';
  static const String usersRefreshToken = '/api/v1/users/{id}/refresh-token';
  static const String usersMe = '/api/v1/users/me';
  static const String users = '/api/v1/users';
  static const String usersById = '/api/v1/users/{id}';

  //* IAP
  static const String packages = '/rest/v1/rpc/p_get_package';
  static const String purchase = '/rest/v1/rpc/p_purchase_package';
  static const String restore = '/rest/v1/rpc/p_restore_package';
  static const String verifyIos = '/functions/v1/validate_ios_receipt';
  static const String verifyIosV111 = '/functions/v1/validate_ios_receipt_v1_1_1';
  static const String verifyAndroid = '/functions/v1/validate_android_receipt';

  //* Onboardings API
  static const String onboardings = '/api/v1/onboardings';
  static const String onboardingsById = '/api/v1/onboardings/{id}';

  //* Chats API
  static const String chatMessages = '/api/v1/chats/messages';

  //* Courses API
  static const String courses = '/api/v1/courses';
  static const String coursesById = '/api/v1/courses/{id}';
  static const String coursesRoadmap = '/api/v1/courses/{id}/roadmap';

  //* Courses Lessons API
  static const String coursesLessons = '/api/v1/courses-lessons';
  static const String coursesLessonsById = '/api/v1/courses-lessons/{id}';
  static const String coursesLessonsIndexes = '/api/v1/courses-lessons/indexs';

  //* Courses Keypoints API
  static const String coursesKeypoints = '/api/v1/courses-keypoints';
  static const String coursesKeypointsById = '/api/v1/courses-keypoints/{id}';

  //* Courses Learning Items API
  static const String coursesLearningItems = '/api/v1/courses-learning-items';
  static const String coursesLearningItemsById = '/api/v1/courses-learning-items/{id}';

  //* Courses User Progress API
  static const String coursesUserProgress = '/api/v1/courses-user-progress';
  static const String coursesUserProgressLesson = '/api/v1/courses-user-progress/lesson/:lessonId';
  static const String coursesUserProgressKeypoint = '/api/v1/courses-user-progress/keypoint/:keypointId';
  static const String coursesUserProgressExercise = '/api/v1/courses-user-progress/exercise/:exerciseId';
  static const String coursesUserProgressKeypointsPassed = '/api/v1/courses-user-progress/keypoints-passed';
}
