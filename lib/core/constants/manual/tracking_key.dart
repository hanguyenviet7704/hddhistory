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
  static const String allCourseScrView = 'all_course_scr_view';
  static const String allCourseSkillSwitch = 'all_course_skill_switch';
  static const String allCourseCourseClick = 'all_course_course_click';
  static const String allCourseFirstCourseClick = 'all_course_1stcourse_click';
  static const String allCourseExit = 'all_course_exit';

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

  //* Draw welcome screen events
  static const String drawWelcomeScrView = 'draw_welcome_scr_view';
  static const String drawWelcomeScrViewSkip = 'draw_welcome_scr_view_skip';
  static const String drawWelcomeTopicScrView = 'draw_welcome_topic_scr_view';
  static const String drawWelcomeTopicSelect = 'draw_welcome_topic_select';
  static const String drawWelcomeTopicIntroScrView = 'draw_welcome_topic_intro_scr_view';
  static const String drawWelcomeTopicIntroSkip = 'draw_welcome_topic_intro_skip';
  static const String drawWelcomeArtScrView = 'draw_welcome_art_scr_view';
  static const String drawWelcomeArtCtaClick = 'draw_welcome_art_CTA_click';

  //* Draw roadmap events
  static const String drawRoadmapScrView = 'draw_roadmap_scr_view';
  static const String drawRoadmapTopicClick = 'draw_roadmap_topic_click';
  static const String drawClick = 'draw_click';
  static const String drawRoadmapLoginReminder1View = 'draw_roadmap_login_reminder1_view';
  static const String drawRoadmapLoginReminder1Click = 'draw_roadmap_login_reminder1_click';
  static const String drawRoadmapLoginReminder2View = 'draw_roadmap_login_reminder2_view';
  static const String drawRoadmapLoginReminder2Click = 'draw_roadmap_login_reminder2_click';
  
  //* Draw roadmap picture events
  static const String drawRoadmapPicClick = 'draw_roadmap_pic_click';
  static const String drawRoadmapPicPreview = 'draw_roadmap_pic_preview';
  static const String drawRoadmapPicPreviewExit = 'draw_roadmap_pic_preview_exit';
  static const String drawRoadmapPicCtaClick = 'draw_roadmap_pic_CTA_click';
  static const String drawRoadmapLessonClick = 'draw_roadmap_lesson_click';

  //* Draw roadmap topic events
  static const String drawRoadmapTopicStoryView = 'draw_roadmap_topic_story_view';
  static const String drawRoadmapTopicStoryBack = 'draw_roadmap_topic_story_back';

  //* Draw canvas screen events
  static const String drawCanvasScrView = 'draw_canvas_scr_view';
  static const String drawCanvasExitDialogView = 'draw_canvas_exit_dialog_view';
  static const String drawCanvasExitDialogConfirm = 'draw_canvas_exit_dialog_confirm';

  //* Draw canvas guide events
  static const String drawCanvasGuideView = 'draw_canvas_guide_view';
  static const String drawCanvasTutorialNextClick = 'draw_canvas_tutorial_next_click';
  static const String drawCanvasPlayguideClick = 'draw_canvas_playguide_click';

  //* Draw canvas tool interaction events
  static const String drawCanvasToolClick = 'draw_canvas_tool_click';
  static const String drawCanvasToolUse = 'draw_canvas_tool_use';
  static const String drawCanvasLineSlide = 'draw_canvas_line_slide';
  static const String drawCanvasEraseSizeSlide = 'draw_canvas_erase_size_slide';

  //* Draw canvas palette events
  static const String drawCanvasPallateView = 'draw_canvas_pallate_view';
  static const String drawCanvasPallateColorPick = 'draw_canvas_pallate_color_pick';
  static const String drawCanvasPallateDropperClick = 'draw_canvas_pallate_dropper_click';
  static const String drawCanvasPallateDropperUse = 'draw_canvas_pallate_dropper_use';

  //* Draw canvas booster events
  static const String drawCanvasBoosterClick = 'draw_canvas_booster_click';
  static const String drawCanvasBoosterUse = 'draw_canvas_booster_use';

  //* Draw canvas submission event
  static const String drawCanvasSubmitClick = 'draw_canvas_submit_click';
  // Draw canvas submission event
  static const String curriculumCompleted = 'curriculum_completed';

  //* Draw result screen events (lose)
  static const String drawResultLoseScrView = 'draw_result_lose_scr_view';
  static const String drawResultLoseTipClick = 'draw_draw_result_lose_tip_click';
  static const String drawResultLoseTryagainClick = 'draw_result_lose_tryagain_click';
  static const String drawResultLoseExit = 'draw_result_lose_exit';

  //* Draw result screen events (win)
  static const String drawResultWinScrView = 'draw_result_win_scr_view';
  static const String drawResultWinTipClick = 'draw_result_win_tip_click';
  static const String drawResultWinTryagainClick = 'draw_result_win_tryagain_click';
  static const String drawResultWinExit = 'draw_result_win_exit';
  static const String drawResultWinNextLessonClick = 'draw_result_win_next_lesson_click';

  //* Draw result screen events (AI)
  static const String drawResultAIScrView = 'draw_result_ai_scr_view';
  static const String drawResultAINextLessonClick = 'draw_result_ai_next_lesson_click';
  static const String drawResultAIExit = 'draw_result_ai_exit';

  //* Profile screen events
  static const String profileView = 'profile_view';
  static const String profileLanguageView = 'profile_language_view';
  static const String profileLanguageSelect = 'profile_language_select';
  static const String profileSignoutClick = 'profile_signout_click';
  static const String profileUpgradeClick = 'profile_upgrade_click';
  static const String profileSettingClick = 'profile_setting_click';

  //* Survey screen events
  static const String drawSurveyPopupView = 'draw_survey_popup_view';
  static const String drawSurveyPopupResponse = 'draw_survey_popup_response';

  //* Feedback screen events (first feedback)
  static const String feedback1ScrView = 'feedback1_scr_view';
  static const String feedback1FirstImpressClick = 'feedback1_first_impress_click';
  static const String feedback1TextClick = 'feedback1_text_click';
  static const String feedback1SubmitClick = 'feedback1_submit_click';
  static const String feedback1Exit = 'feedback1_exit';

  //* Feedback screen events (second feedback)
  static const String feedback2ScrView = 'feedback2_scr_view';
  static const String feedback2RatingTypeClick = 'feedback2_rating_type_click';
  static const String feedback2TextClick = 'feedback2_text_click';
  static const String feedback2SubmitClick = 'feedback2_submit_click';
  static const String feedback2Exit = 'feedback2_exit';
  static const String feedback3ScrView = 'feedback3_scr_view';
  static const String feedback3RatingTypeClick = 'feedback3_rating_type_click';
  static const String feedback3TagClick = 'feedback3_tag_click';
  static const String feedback3TextClick = 'feedback3_text_click';
  static const String feedback3SubmitClick = 'feedback3_submit_click';
  static const String feedback3Exit = 'feedback3_exit';
  static const String feedback3ThankExit = 'feedback3_thank_exit';
  
  //* Sign-in events
  static const String signinSrcView = 'signin_src_view';
  static const String signinSigninClick = 'signin_signin_click';
  static const String signinSigninGoogleClick = 'signin_signin_google_click';
  static const String signinSigninAppleClick = 'signin_signin_apple_click';
  static const String signinForgotPasswordClick = 'signin_forgot_password_click';
  static const String signinCreateAccountClick = 'signin_create_account_click';
  static const String signinExit = 'signin_exit';

  //* Sign-up events
  static const String signupSrcView = 'signup_src_view';
  static const String signupCreateAccountClick = 'signup_create_account_click';
  static const String signupGoogleContinueClick = 'signup_google_countinue_click';
  static const String signupAppleContinueClick = 'signup_apple_countinue_click';
  static const String signupSigninClick = 'signup_signin_click';
  static const String signupExit = 'signup_exit';

  //* Share screen events
  static const String shareScrView = 'share_scr_view';
  static const String shareDownloadClick = 'share_download_click';
  static const String shareCopyLinkClick = 'share_copy_link_click';
  static const String shareSharetoClick = 'share_shareto_click';
  static const String shareExit = 'share_exit';

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

  //* Paywall package events
  static const String discordLinkClick = 'discord_link_click';
  static const String toastCloseClick = 'toast_close_click';
}
