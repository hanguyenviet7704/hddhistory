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
  static const String onboardIntroduce = '/onboard-introduce';
  static const String noAuth = '/no-auth';

  //* Monetization
  static const String paywall = '/paywall';

  //* Onboard
  static const String onboard = '/onboard';
  static const String onboardBranching = '/onboard-branching';
  static const String onboardV2 = '/onboard-v2';
  static const String dataCollect = '/data-collect';
  static const String dataCollectMotivationStep = '/data-collect-motivation-step/:step';
  static const String dataCollectFeedback = '/data-collect-feedback';
  static const String dataCollectSummary = '/data-collect-summary';
  static const String notificationRequest = '/notification-request';

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
  static const String homeLearningStreak = 'learning-streak';
  static const String dailyWarmUp = 'daily-warm-up';

  //* Course
  static const String course = '/course';
  static const String courseRoadmap = '/course-roadmap';
  static const String changeCourse = 'change-course';
  static const String skillsetCourses = 'skillset-courses/:skillsetId';
  static const String lessonList = 'lesson-list';
  static const String lessonExplainPopup = 'lesson-explain-popup';
  static const String courseLessonEmptyNotiPopup = 'course-lesson-empty-noti-popup';

  //? Course - Warm Up (return-refresher)
  static const String warmUpIntro = 'warm-up-intro';
  static const String warmUpQuestion = 'warm-up-question';
  static const String warmUpCompletion = 'warm-up-completion';

  //? Course - Lesson
  static const String lesson = 'lesson';
  static const String noCorrectAnswerDocument = 'no-correct-answer-document/:groupId';
  static const String reviewTime = 'review-time';
  static const String keypointComplete = 'keypoint-complete';
  static const String badgeProgress = 'badge-progress';
  static const String exerciseResultPopup = 'exercise-result-popup';

  //? Course - Roleplay
  static const String roleplayIntroPopup = 'roleplay-intro-popup';
  static const String roleplayIntro = 'roleplay-intro';
  static const String roleplay = 'roleplay';
  static const String roleplayFeedback = 'roleplay-feedback';
  static const String roleplayComplete = 'roleplay-complete';
  static const String outputPractice = 'output-practice/:sectionId';
  static const String videoLesson = 'video-lesson/:courseId/:nodeId/:lessonId';

  //* Setting - Profile
  static const String profile = '/profile';
  static const String setting = 'setting';
  static const String profileInfo = 'profile-info';
  static const String notification = 'notification';
  static const String changeLanguage = 'change-language';
  static const String manageSubscription = 'manage-subscription';
  static const String profileDeleteDialog = 'profile-delete-dialog';
  static const String userAchievementBottomSheet = 'user-achievement-bottom-sheet';
  static const String reportIssueSheet = 'report-issue-sheet';

  //* Setting - Learning import (user's own PDF / YouTube -> generated lesson)
  // Nested under /profile: these lessons are the user's own shelf, not
  // catalogue content, so they belong behind the profile tab rather than in
  // Home or the course roadmap.
  static const String myLessons = 'my-lessons';
  static const String lessonReader = 'lesson-reader/:lessonId';
  static const String importLesson = 'import-lesson';
  static const String importGenerating = 'import-generating';

  //* Habit
  static const String habit = '/habit';
  static const String dailyCheckIn = 'daily-check-in';
  static const String habitSummary = '/habit-summary';
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
  static const String onboardIntroduce = 'Onboard Introduce Page';
  static const String noAuth = 'No Auth Page';

  //* Monetization
  static const String paywall = 'Paywall Page';

  //* Onboard
  static const String onboard = 'Onboard Page';
  static const String onboardBranching = 'Onboard Branching Page';
  static const String onboardV2 = 'Onboard V2 Page';
  static const String dataCollect = 'Data Collect Page';
  static const String dataCollectMotivationStep = 'Data Collect Motivation Step Page';
  static const String dataCollectFeedback = 'Data Collect Feedback Page';
  static const String dataCollectSummary = 'Data Collect Summary Page';
  static const String notificationRequest = 'Notification Request Page';

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
  static const String homeLearningStreak = 'Home Learning Streak';
  static const String dailyWarmUp = 'Daily Warm Up';

  //* Course
  static const String course = 'Course';
  static const String courseRoadmap = 'Course Roadmap';
  static const String changeCourse = 'Change Course';
  static const String skillsetCourses = 'Skillset Courses';
  static const String lessonList = 'Lesson List';
  static const String lessonExplainPopup = 'Lesson Explain Popup';
  static const String roadmapDetailPopup = 'Roadmap Detail Popup';
  static const String courseLessonEmptyNotiPopup = 'Course Lesson Empty Noti Popup';

  //? Course - Warm Up (return-refresher)
  static const String warmUpIntro = 'Warm Up Intro';
  static const String warmUpQuestion = 'Warm Up Question';
  static const String warmUpCompletion = 'Warm Up Completion';

  //? Course - Lesson
  static const String lesson = 'Lesson';
  static const String noCorrectAnswerDocument = 'No Correct Answer Document';
  static const String reviewTime = 'Review Time';
  static const String keypointComplete = 'Keypoint Complete';
  static const String badgeProgress = 'Badge Progress';
  static const String exerciseResultPopup = 'Exercise Result Popup';

  //? Course - Roleplay
  static const String roleplayIntroPopup = 'Roleplay Intro Popup';
  static const String roleplay = 'Roleplay';
  static const String roleplayIntro = 'Roleplay Intro';
  static const String roleplayFeedback = 'Roleplay Feedback';
  static const String roleplayComplete = 'Roleplay Complete';
  static const String outputPractice = 'Output Practice';
  static const String videoLesson = 'Video Lesson';

  //? Feedback
  static const String feedbackCompleteLessonPopup = 'Feedback Complete Lesson Popup';
  static const String feedbackIncompleteLessonPopup = 'Feedback Incomplete Lesson Popup';
  static const String feedbackBeforeYouGoPopup = 'Feedback Before You Go Popup';

  //* Setting - Profile
  static const String setting = 'Setting';
  static const String profile = 'Profile';
  static const String profileInfo = 'Profile Info';
  static const String notification = 'Notification';
  static const String changeLanguage = 'Change Language';
  static const String manageSubscription = 'Manage Subscription';
  static const String profileDeleteDialog = 'Profile Delete Dialog';
  static const String userAchievementBottomSheet = 'User Achievement Bottom Sheet';
  static const String reportIssueSheet = 'Report Issue Sheet';

  //* Setting - Learning import
  static const String myLessons = 'My Lessons';
  static const String lessonReader = 'Lesson Reader';
  static const String importLesson = 'Import Lesson';
  static const String importGenerating = 'Import Generating';

  //* Habit
  static const String habit = 'Habit';
  static const String dailyCheckIn = 'Daily Check In';
  static const String habitSummary = 'Habit Summary';
}

/// Route names (PageCubit stores [RouteNamed], e.g. 'Register Page' — NOT
/// [RoutePath] like '/register') where the user has NOT yet reached an
/// authenticated area: bootstrap/splash + the whole auth & onboarding flow. A
/// 401 here is a routine expired/guest token, so the app logs out silently
/// instead of shoving a scary "session expired" toast in front of onboarding for
/// a user who never actively logged in. '' covers the first frame before the
/// route observer reports anything.
const Set<String> preAuthRouteNames = {
  '',
  RouteNamed.splash,
  RouteNamed.chooseLanguage,
  RouteNamed.onboardIntroduce,
  RouteNamed.noAuth,
  RouteNamed.onboard,
  RouteNamed.onboardBranching,
  RouteNamed.onboardV2,
  RouteNamed.dataCollect,
  RouteNamed.dataCollectMotivationStep,
  RouteNamed.dataCollectFeedback,
  RouteNamed.dataCollectSummary,
  RouteNamed.notificationRequest,
  RouteNamed.login,
  RouteNamed.register,
  RouteNamed.registerAuth,
  RouteNamed.forgotPassword,
  RouteNamed.otp,
  RouteNamed.setupPassword,
  RouteNamed.changePassword,
};

/// Whether a session reset should force-navigate to the welcome/register screen.
///
/// Only true when the session died on an AUTHENTICATED screen. From a pre-auth
/// screen it must stay false: going to RegisterRoute while already on it
/// REPLACES the page with a fresh instance whose mount-time guest bootstrap
/// restarts, and a burst of 401s re-fires the reset every couple of seconds —
/// the welcome screen then remounts forever and never becomes interactive
/// ("xoá app cài lại → màn login không bấm được gì"). Splash and the onboarding
/// flow own their own routing and must not be hijacked either.
bool shouldForceRegisterNavigationAfterReset(String currentRouteName) =>
    !preAuthRouteNames.contains(currentRouteName);
