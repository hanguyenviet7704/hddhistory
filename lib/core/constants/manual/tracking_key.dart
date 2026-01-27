part of '../constants.dart';

mixin TrackingKey {
  //* Splash screen events
  static const String splashScrView = 'splash_scr_view';

  //* Onboarding events
  static const String obdIntro1ScrView = 'obd_intro1_scr_view';
  static const String obdIntro1Continue = 'obd_intro1_continue';
  static const String obdIntro2ScrView = 'obd_intro2_scr_view';
  static const String obdIntro2Click = 'obd_intro2_click';
  static const String obdLanguagePopupView = 'obd_language_popup_view';
  static const String obdLanguageClick = 'obd_language_click';
  static const String obdNameScrView = 'obd_name_scr_view';
  static const String obdNameClick = 'obd_name_click';
  static const String obdNameContinue = 'obd_name_continue';
  static const String obdWelcomeScrView = 'obd_welcome_scr_view';
  static const String obdWelcomeContinue = 'obd_welcome_continue';
  static const String obdAgeScrView = 'obd_age_scr_view';
  static const String obdAgeClick = 'obd_age_click';
  static const String obdAgeContinue = 'obd_age_continue';
  static const String obdAgeBack = 'obd_age_back';
  static const String obdGenderScrView = 'obd_gender_scr_view';
  static const String obdGenderClick = 'obd_gender_click';
  static const String obdGenderContinue = 'obd_gender_continue';
  static const String obdGenderBack = 'obd_gender_back';
  static const String obdLearningGoalScrView = 'obd_learning_goal_scr_view';
  static const String obdLearningGoalClick = 'obd_learning_goal_click';
  static const String obdLearningGoalContinue = 'obd_learning_goal_continue';
  static const String obdLearningGoalBack = 'obd_learning_goal_back';
  static const String obdSkillsetScrView = 'obd_skillset_scr_view';
  static const String obdSkillsetClick = 'obd_skillset_click';
  static const String obdSkillsetContinue = 'obd_skillset_continue';
  static const String obdSkillsetBack = 'obd_skillset_back';
  static const String obdMotivation1ScrView = 'obd_motivation1_scr_view';
  static const String obdMotivation1Continue = 'obd_motivation1_continue';
  static const String obdStrugglesScrView = 'obd_struggles_scr_view';
  static const String obdStrugglesClick = 'obd_struggles_click';
  static const String obdStrugglesContinue = 'obd_struggles_continue';
  static const String obdStrugglesBack = 'obd_struggles_back';
  static const String obdMotivation2ScrView = 'obd_motivation2_scr_view';
  static const String obdMotivation2Continue = 'obd_motivation2_continue';
  static const String obdHowToLearnScrView = 'obd_how_to_learn_scr_view';
  static const String obdHowToLearnSwipe = 'obd_how_to_learn_swipe';
  static const String obdHowToLearnContinue = 'obd_how_to_learn_continue';
  static const String obdHowToLearnBack = 'obd_how_to_learn_back';
  static const String obdFeedbackScrView = 'obd_feedback_scr_view';
  static const String obdFeedbackSwipe = 'obd_feedback_swipe';
  static const String obdFeedbackContinue = 'obd_feedback_continue';
  static const String obdDailyTimeScrView = 'obd_daily_time_scr_view';
  static const String obdDailyTimeClick = 'obd_daily_time_click';
  static const String obdDailyTimeContinue = 'obd_daily_time_continue';
  static const String obdDailyTimeBack = 'obd_daily_time_back';
  static const String obdLearningTimeScrView = 'obd_learning_time_scr_view';
  static const String obdLearningTimeClick = 'obd_learning_time_click';
  static const String obdLearningTimeContinue = 'obd_learning_time_continue';
  static const String obdLearningTimeBack = 'obd_learning_time_back';
  static const String obdMotivation3ScrView = 'obd_motivation3_scr_view';
  static const String obdMotivation3Click = 'obd_motivation3_click';
  static const String obdCompleteScrView = 'obd_complete_scr_view';
  static const String obdCompleteClick = 'obd_complete_click';

  //* Home events
  static const String homeScrView = 'home_scr_view';
  static const String homeTabSwitch = 'home_tab_switch';
  static const String homeSkillClick = 'home_skill_click';

  //* Course selection events
  static const String courseSelectAllCourseView = 'course_select_all_course_view';
  static const String courseSelectMyCourseView = 'course_select_my_course_view';
  static const String courseSelectCategorySlide = 'course_select_category_slide';
  static const String courseSelectCategoryClick = 'course_select_category_click';
  static const String courseSelectFirstCourseClick = 'course_select_1stcourse_click';
  static const String courseSelectExit = 'course_select_exit';
  static const String courseSelectAllCourseScroll = 'course_select_all_course_scroll';

  //* Course events
  static const String popupLearningIntroScrView = 'popup_learning_intro_scr_view';
  static const String popupLearningIntroContinue = 'popup_learning_intro_continue';
  static const String popupLearningIntroSwipe = 'popup_learning_intro_swipe';
  static const String roadmapScrView = 'roadmap_scr_view';
  static const String roadmapItemClick = 'roadmap_item_click';
  static const String howItWorkScrView = 'how_it_work_scr_view';
  static const String howItWorkDoneClick = 'how_it_work_done_click';
  static const String howItWorkExitTap = 'how_it_work_exit_tap';
  static const String howItWorkClick = 'how_it_work_click';
  static const String lessonKeypointScrView = 'lesson_keypoint_scr_view';
  static const String lessonKeypointExit = 'lesson_keypoint_exit';
  static const String lessonKeypointClick = 'lesson_keypoint_click';

  //* Keypoint events
  static const String keypointTheoryScrView = 'keypoint_theory_scr_view';
  static const String keypointTheoryContinueClick = 'keypoint_theory_continue_click';
  static const String keypointExerciseScrView = 'keypoint_exercise_scr_view';
  static const String keypointExerciseClick = 'keypoint_exercise_click';
  static const String keypointExerciseMultiClick = 'keypoint_exercise_multi_click';
  static const String keypointExerciseDrag = 'keypoint_exercise_drag';
  static const String keypointExerciseArrange = 'keypoint_exercise_arrange';
  static const String keypointExerciseRecordAnswer = 'keypoint_exercise_record_answer';
  static const String keypointExerciseRecordTyping = 'keypoint_exercise_record_typing';
  static const String keypointExerciseRecordVoice = 'keypoint_exercise_record_voice';
  static const String keypointExerciseCheckClick = 'keypoint_exercise_check_click';
  static const String keypointExerciseResultView = 'keypoint_exercise_result_view';
  static const String keypointExerciseExplainClick = 'keypoint_exercise_explain_click';
  static const String keypointExerciseExplainView = 'keypoint_exercise_explain_view';
  static const String keypointExerciseExplainReplay = 'keypoint_exercise_explain_replay';
  static const String keypointExerciseScroll = 'keypoint_exercise_scroll';
  static const String keypointExerciseContinue = 'keypoint_exercise_continue';
  static const String keypointExerciseExplainClose = 'keypoint_exercise_explain_close';
  static const String keypointFinishScrView = 'keypoint_finish_scr_view';
  static const String lessonFinishScrView = 'lesson_finish_scr_view';
  static const String keypointExitClick = 'keypoint_exit_click';
  static const String keypointExitPopupView = 'keypoint_exit_popup_view';
  static const String keypointExitPopupClick = 'keypoint_exit_popup_click';

  //* Roleplay events
  static const String roleplayInfoScrView = 'roleplay_info_scr_view';
  static const String roleplayInfoContinueClick = 'roleplay_info_continue_click';
  static const String roleplayOverviewExitClick = 'roleplay_overview_exit_click';
  static const String roleplayOverviewScroll = 'roleplay_overview_scroll';
  static const String roleplayMissionsView = 'roleplay_missions_view';
  static const String roleplayMissionsScroll = 'roleplay_missions_scroll';
  static const String roleplayStartClick = 'roleplay_start_click';
  static const String roleplayConvScrView = 'roleplay_conv_scr_view';
  static const String roleplayConvExitClick = 'roleplay_conv_exit_click';
  static const String roleplayConvScroll = 'roleplay_conv_scroll';
  static const String roleplayVoiceInteraction = 'roleplay_voice_interaction';
  static const String roleplayQuizImp = 'roleplay_quiz_imp';
  static const String roleplayQuizClick = 'roleplay_quiz_click';
  static const String roleplayQuizExpandedView = 'roleplay_quiz_expanded_view';
  static const String roleplayQuizExpandedClose = 'roleplay_quiz_expanded_close';
  static const String roleplayQuizSingSelect = 'roleplay_quiz_sing_select';
  static const String roleplayQuizMultiSelect = 'roleplay_quiz_multi_select';
  static const String roleplayQuizDrag = 'roleplay_quiz_drag';
  static const String roleplayQuizArrange = 'roleplay_quiz_arrange';
  static const String roleplayQuizRecordAns = 'roleplay_quiz_record_ans';
  static const String roleplayQuizRecordTyping = 'roleplay_quiz_record_typing';
  static const String roleplayQuizRecordVoice = 'roleplay_quiz_record_voice';
  static const String roleplayQuizCheck = 'roleplay_quiz_check';
  static const String roleplayQuizResultView = 'roleplay_quiz_result_view';
  static const String roleplayQuizResultScroll = 'roleplay_quiz_result_scroll';
  static const String roleplayQuizContinue = 'roleplay_quiz_continue';
  static const String roleplayQuizReviewReplay = 'roleplay_quiz_review_replay';
  static const String roleplayQuizCollapsedClick = 'roleplay_quiz_collapsed_click';
  static const String roleplayQuizCollapsedReplay = 'roleplay_quiz_collapsed_replay';
  static const String roleplayCompleteClick = 'roleplay_complete_click';
  static const String roleplayDoneScrView = 'roleplay_done_scr_view';
  static const String roleplayDoneResultClick = 'roleplay_done_result_click';
  static const String roleplayResultScrView = 'roleplay_result_scr_view';
  static const String roleplayResultScroll = 'roleplay_result_scroll';
  static const String roleplayResultContinue = 'roleplay_result_continue';
  static const String badgeCompleteScrView = 'badge_complete_scr_view';

  //* Feedback events
  static const String feedbackCompleteLessonView = 'feedback_complete_lesson_view';
  static const String feedbackCompleteLessonSend = 'feedback_complete_lesson_send';
  static const String feedbackIncompleteLessonView = 'feedback_incomplete_lesson_view';
  static const String feedbackIncompleteLessonSend = 'feedback_incomplete_lesson_send';

  //* Profile screen events
  static const String profileView = 'profile_view';
  static const String profileLanguageView = 'profile_language_view';
  static const String profileLanguageSelect = 'profile_language_select';
  static const String profileSignoutClick = 'profile_signout_click';
  static const String profileUpgradeClick = 'profile_upgrade_click';
  static const String profileSettingClick = 'profile_setting_click';

  //* Setting screen events
  static const String settingScrView = 'setting_scr_view';
  static const String settingScroll = 'setting_scroll';
  static const String settingProfileClick = 'setting_profile_click';
  static const String settingProfileEditClick = 'setting_profile_edit_click';
  static const String settingProfileDoneClick = 'setting_profile_done_click';
  static const String settingProfileDeleteClick = 'setting_profile_delete_click';
  static const String profileDeleteScrView = 'profile_delete_scr_view';
  static const String profileDeleteOptionClick = 'profile_delete_option_click';
  static const String settingDetailClick = 'setting_detail_click';
  static const String settingDetailScrView = 'setting_detail_scr_view';
  static const String settingLanguageClick = 'setting_language_click';
  static const String settingLanguageScrView = 'setting_language_scr_view';
  static const String settingTermClick = 'setting_term_click';
  static const String settingRestorePurcClick = 'setting_restore_purc_click';
  static const String settingLogoutClick = 'setting_logout_click';
  static const String settingPremiumClick = 'setting_premium_click';
  static const String premiumScrView = 'premium_scr_view';
  static const String premiumScroll = 'premium_scroll';
  static const String premiumInforSwipe = 'premium_infor_swipe';
  static const String premiumRestoreClick = 'premium_restore_click';
  static const String premiumPurchase = 'premium_purchase';
  static const String premiumScrExit = 'premium_scr_exit';
  static const String premiumAllpackClick = 'premium_allpack_click';
  static const String premiumAllpackScrView = 'premium_allpack_scr_view';
  static const String premiumAllpackPick = 'premium_allpack_pick';
  static const String premiumAllpackPurchase = 'premium_allpack_purchase';
  static const String settingBadgeClick = 'setting_badge_click';
  static const String settingBadgeSlide = 'setting_badge_slide';
  static const String settingBadgeDetailView = 'setting_badge_detail_view';
  static const String settingBadgeDetailSlide = 'setting_badge_detail_slide';
  static const String settingBadgeGoCourse = 'setting_badge_go_course';

  //* Paywall screen events
  static const String paywallScrView = 'paywall_scr_view';
  static const String paywallPackageClick = 'paywall_package_click';
  static const String paywallExitClick = 'paywall_exit_click';
  static const String paywallStartPremiumClick = 'paywall_start_premium_click';
  static const String paywallStorePopupDismiss = 'paywall_store_popup_dismiss';

  //* Subscription events
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String subscriptionExpired = 'subscription_expired';
  static const String subscriptionFailed = 'subscription_failed';
  static const String subscriptionCompleted = 'subscription_completed';
}
