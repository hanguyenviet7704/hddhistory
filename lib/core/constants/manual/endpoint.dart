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
  static const String getUserProfile = '/api/v1/users/me';
  static const String users = '/api/v1/users';
  static const String usersById = '/api/v1/users/{id}';
  static const String userByDeviceId = '/api/v1/users/check-onboarding/{deviceId}';

  //* IAP
  static const String packages = '/api/v1/payment/products';
  static const String verify = '/api/v1/payment/purchases/verify';
  static const String userIapSubscriptions = '/api/v1/payment/subscriptions/users/{userId}/active-premium';

  //* Onboardings API
  static const String onboardings = '/api/v1/onboardings';
  static const String onboardingsScenarios = '/api/v2/onboardings';
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

  //* Courses Tags API
  static const String coursesTags = '/api/v1/courses-tags';
  static const String coursesTagsById = '/api/v1/courses-tags/{id}';

  //* Courses Feedback API
  static const String coursesFeedbacks = '/api/v1/courses-feedback';
  static const String coursesFeedbacksOfUser = '/api/v1/courses-feedback/me';

  //* Courses Reports API
  static const String coursesReports = '/api/v1/courses-reports';

  //* Courses Search History API
  static const String coursesSearchHistory = '/api/v1/courses-search-history';

  //* Courses Recently Viewed API
  static const String coursesRecentlyViewed = '/api/v1/courses-recently-viewed';

  //* Courses User Progress API
  static const String coursesUserProgress = '/api/v1/courses-user-progress';
  static const String coursesUserProgressLesson = '/api/v1/courses-user-progress/lesson/{lessonId}';
  static const String coursesUserProgressKeypoint = '/api/v1/courses-user-progress/keypoints';
  static const String coursesUserProgressExercise = '/api/v1/courses-user-progress/exercises';
  static const String coursesUserProgressMyCourses = '/api/v1/courses-user-progress/my-course';
  static const String coursesUserProgressAchievements = '/api/v1/courses-user-progress/achievements';
  static const String coursesUserProgressBadgeProgress = '/api/v1/courses-user-progress/badge-progress/{courseId}';
  static const String coursesUserProgressStreak = '/api/v1/courses-user-progress/streak';
  static const String coursesUserProgressWidgetInProgress = '/api/v1/courses-user-progress/widget/in-progress';
  static const String coursesUserProgressWidgetSuggestCourse = '/api/v1/courses-user-progress/widget/suggest-course';
  static const String coursesQuotesRandom = '/api/v1/courses-quotes/random';
  static const String coursesUserProgressSuggestCourses = '/api/v1/courses-user-progress/suggest-courses';
  static const String coursesUserProgressCompletedLevelAdditionalContentRequest = '/api/v1/courses-user-progress/completed-level/additional-content-request';

  //* Courses Output Practice API
  static const String coursesOutputPracticeConversations = '/api/v1/courses-output-practice-conversations';
  static const String coursesOutputPracticeSectionConversations = '/api/v1/courses-output-practice-conversations/section/{sectionId}';
  static const String coursesOutputPracticeSectionConversationsUsage = '/api/v1/courses-output-practice-conversations/section/{sectionId}/usage';
  static const String coursesOutputPracticeMessages = '/api/v1/courses-output-practice-messages';
  static const String coursesOutputPracticeMessagesSend = '/api/v1/courses-output-practice-messages/send';

  //* Course User Video Lessons Activity API
  static const String coursesUserVideoLessonsActivity = '/api/v1/courses-user-video-lesson-activity';
  static const String coursesUserVideoLessonsActivityById = '/api/v1/courses-user-video-lesson-activity/{id}';

  //* Daily Warm Up API
  static const String dailyWarmUp = '/api/v1/courses-user-progress/daily-warm-up';

  //* Warm Up (return-refresher) API
  static const String warmUpForCourse = '/api/v1/warm-up/for-course/{courseId}';

  //* In App Survey API
  static const String inAppSurveyConfigs = '/api/v1/courses-in-app-survey/config';
  static const String inAppSurveyResponses = '/api/v1/courses-in-app-survey/responses';

  //* Skillsets API
  static const String skillsets = '/api/v1/skillsets';
  static const String skillsetsById = '/api/v1/skillsets/{id}';

  //* Cloudflare Files API
  static const String cloudflareUpload = '/api/v1/cloudflares/upload';
  static const String cloudflareUploadMultiple = '/api/v1/cloudflares/upload-multiple';
  static const String cloudflareDownload = '/api/v1/cloudflares/download/{key}';
  static const String cloudflareInfo = '/api/v1/cloudflares/info/{key}';
  static const String cloudflareList = '/api/v1/cloudflares';
  static const String cloudflareDelete = '/api/v1/cloudflares/{key}';

  //* AI Services API
  static const String voiceFeedback = '/feedback';
  static const String voiceFeedbackStream = '/feedback-stream';
  static const String scoreRecord = '/score-record';
  static const String feedbackRoleplay = '/feedback-roleplay';
}
