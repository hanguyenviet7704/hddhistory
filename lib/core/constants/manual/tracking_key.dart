part of '../constants.dart';

mixin TrackingKey {
  //* Splash screen events
  static const String splashScrView = 'splash_scr_view';
  static const String notiPermission = 'noti_permission';

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
