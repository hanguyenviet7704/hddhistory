part of '../constants.dart';

mixin AppEndpoint {
  //* GraphQL
  static const String graphql = '/graphql';

  //* Auth
  static const String login = '/auth/v1/signup';
  static const String register = '/auth/v1/signup';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String resendOTP = '/resend-otp';
  static const String verifyOTP = '/verify-otp';
  static const String updatePassword = '/user/update-password';
  static const String deletePermanentUser = '/user/delete-permanently-user';
  static const String deleteAccount = '/functions/v1/delete-my-account';
  static const String changeProfileId = '/rest/v1/rpc/p_change_user_profile_id';

  //* Config
  static const String config = '/config';
  static const String appName = '/config/app-name';
  static const String splash = '/config/splashes';
  static const String termsOfUseApp = '/config/terms-of-use-app';
  static const String termsOfSalePolicy = '/config/terms-of-sale-policy';
  static const String privacyPolicy = '/config/privacy-policy';

  //* Lesson
  static const String startLesson = '/rest/v1/rpc/l_start_lesson';
  static const String createArtWork = '/rest/v1/rpc/create_artwork_v1_0_1';
  static const String presignedUpload = '/functions/v1/s3-put-object';

  //* AI
  static const String analyzeArtWork = '/analyze';
  static const String evaluateDrawing = '/evaluate-drawing';
  static const String evaluateDrawingLect2a = '/evaluate-drawing-lect2a';
  static const String evaluateDrawingLect2b = '/evaluate-drawing-lect2b';

  //* Feedback
  static const String createFeedback = '/rest/v1/rpc/upsert_profile_feedback';
  static const String createFeedbackPaywall = '/rest/v1/rpc/upsert_profile_feedback_v1_1_0';

  //* IAP
  static const String packages = '/rest/v1/rpc/p_get_package';
  static const String purchase = '/rest/v1/rpc/p_purchase_package';
  static const String restore = '/rest/v1/rpc/p_restore_package';
  static const String verifyIos = '/functions/v1/validate_ios_receipt';
  static const String verifyIosV111 = '/functions/v1/validate_ios_receipt_v1_1_1';
  static const String verifyAndroid = '/functions/v1/validate_android_receipt';

  //* Picture study
  static const String submitColorPickerResult = '/rest/v1/rpc/l_submit_color_picker_result';
}
