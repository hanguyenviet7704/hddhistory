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
  static const String obdNotificationGateView = 'obd_notification_gate_view';
  static const String obdNotificationNotifyMeClick = 'obd_notification_notify_me_click';
  static const String obdNotificationMaybeLaterClick = 'obd_notification_maybe_later_click';
  static const String obBranchingP1View = 'ob_branching_p1_view';
  static const String obBranchingP1Continue = 'ob_branching_p1_continue';
  static const String obBranchingContentView = 'ob_branching_content_view';
  static const String obBranchingOptionSelect = 'ob_branching_option_select';
  static const String obBranchingP6View = 'ob_branching_p6_view';
  static const String obBranchingP7View = 'ob_branching_p7_view';
  static const String obBranchingTryNowClick = 'ob_branching_try_now_click';
  static const String obBranchingChooseMyselfClick = 'ob_branching_choose_myself_click';
  static const String obBranchingFallback = 'ob_branching_fallback';
  // Onboard v2 (shipped flow). Event-name VALUES are aligned exactly to the
  // "[MeUp] Event Tracking" sheet (tab Onboarding, gid 778226447) — that sheet
  // is the analytics team's source of truth. Constant NAMES keep the pX/step
  // scheme so call sites don't churn; only the fired strings match the spec.
  static const String onboardV2P1View = 'obd_welcome_scr_view';
  static const String onboardV2P1GetStartedClick = 'obd_welcome_get_started';
  static const String onboardV2P2View = 'obd_name_scr_view';
  static const String onboardV2P2ContinueClick = 'obd_name_continue';
  static const String onboardV2P3View = 'obd_age_scr_view';
  // Per-tap age pick — internal telemetry, not a spec event.
  static const String onboardV2AgeSelect = 'onboard_v2_age_select';
  // Spec `obd_age_select`: fired on Age → Continue (carries user property `age`).
  static const String onboardV2P3ContinueClick = 'obd_age_select';
  static const String onboardV2AgeBack = 'obd_age_back';
  static const String onboardV2AnonymousLoginFailure = 'onboard_v2_anonymous_login_failure';
  static const String onboardV2AnonymousLoginSuccess = 'onboard_v2_anonymous_login_success';
  static const String onboardV2UserUpdateFailure = 'onboard_v2_user_update_failure';
  static const String onboardV2UserUpdateSuccess = 'onboard_v2_user_update_success';
  static const String onboardV2P4View = 'obd_notif_scr_view';
  static const String onboardV2P5View = 'obd_paths_scr_view';
  // Per-tap path toggle — internal telemetry, not a spec event.
  static const String onboardV2PathSelect = 'onboard_v2_path_select';
  static const String onboardV2PathUnselect = 'onboard_v2_path_unselect';
  static const String onboardV2PathMaxReached = 'onboard_v2_path_max_reached';
  // Spec `obd_paths_select`: fired on Paths → Continue (user property `path_selected`).
  static const String onboardV2P5ContinueClick = 'obd_paths_select';
  static const String onboardV2PathsBack = 'obd_paths_back';
  // Brain-science info screen (p6 path map).
  static const String onboardV2P6View = 'obd_infor_scr_view';
  static const String onboardV2P6ContinueClick = 'obd_infor_continue';
  static const String onboardV2InforBack = 'obd_infor_back';
  // Notification gate: allow vs maybe-later are now DISTINCT events (previously
  // both fired 'obd_noti_click' — indistinguishable). Both set user property
  // `noti_allowed`.
  static const String onboardV2NotificationNotifyClick = 'obd_notif_allow';
  static const String onboardV2NotificationMaybeLaterClick = 'obd_notif_later';
  static const String onboardV2NotificationResult = 'onboard_v2_notification_result';
  // Habit ("Which one sounds like you?") screen (p7 symptoms).
  static const String onboardV2P7View = 'obd_symptom_scr_view';
  // Per-tap symptom toggle — internal telemetry, not a spec event.
  static const String onboardV2SymptomSelect = 'onboard_v2_symptom_select';
  static const String onboardV2SymptomUnselect = 'onboard_v2_symptom_unselect';
  // Spec `obd_symptom_select`: fired on Habit → Continue (user property `habit_struggle`).
  static const String onboardV2P7ContinueClick = 'obd_symptom_select';
  static const String onboardV2SymptomBack = 'obd_symptom_back';
  static const String onboardV2P8View = 'obd_course_view';
  static const String onboardV2CoursesLoaded = 'onboard_v2_courses_loaded';
  static const String onboardV2CoursesFailure = 'onboard_v2_courses_failure';
  // Spec `obd_course_select`: user property `first_course`.
  static const String onboardV2CourseSelectClick = 'obd_course_select';
  static const String onboardV2P9View = 'obd_theme_scr_view';
  // Per-tap theme pick — internal telemetry, not a spec event.
  static const String onboardV2ThemeSelect = 'onboard_v2_theme_select';
  // Spec `obd_theme_select`: fired on "Start explore" (finishes onboarding).
  static const String onboardV2P9StartExploreClick = 'obd_theme_select';
  static const String onboardV2Complete = 'onboard_v2_complete';

  //* Home events
  static const String homeScrView = 'home_scr_view';
  static const String homeTabSwitch = 'home_tab_switch';
  static const String homeSkillClick = 'home_skill_click';
  static const String homeStreakChipClick = 'home_streak_chip_click';
  static const String homeStreakPopupView = 'home_streak_popup_view';
  static const String homeStreakPopupClose = 'home_streak_popup_close';
  static const String inAppSurveyEntryView = 'in_app_survey_entry_view';
  static const String inAppSurveyEntryClick = 'in_app_survey_entry_click';
  static const String inAppSurveyPopupView = 'in_app_survey_popup_view';
  static const String inAppSurveyPopupClose = 'in_app_survey_popup_close';
  static const String inAppSurveyEmojiClick = 'in_app_survey_emoji_click';
  static const String inAppSurveyClosedQuestionView = 'in_app_survey_closed_question_view';
  static const String inAppSurveyClosedOptionClick = 'in_app_survey_closed_option_click';
  static const String inAppSurveyClosedContinueClick = 'in_app_survey_closed_continue_click';
  static const String inAppSurveyOpenQuestionView = 'in_app_survey_open_question_view';
  static const String inAppSurveySendClick = 'in_app_survey_send_click';
  static const String inAppSurveySendSuccess = 'in_app_survey_send_success';
  static const String inAppSurveySendFailure = 'in_app_survey_send_failure';
  static const String dailyWarmUpEntryCheck = 'daily_warm_up_entry_check';
  static const String dailyWarmUpSkip = 'daily_warm_up_skip';
  static const String dailyWarmUpP1View = 'daily_warm_up_p1_view';
  static const String dailyWarmUpStartClick = 'daily_warm_up_start_click';
  static const String dailyWarmUpMaybeLaterClick = 'daily_warm_up_maybe_later_click';
  static const String dailyWarmUpQuestionView = 'daily_warm_up_question_view';
  static const String dailyWarmUpQuestionCheckClick = 'daily_warm_up_question_check_click';
  static const String dailyWarmUpQuestionResultView = 'daily_warm_up_question_result_view';
  static const String dailyWarmUpQuestionContinueClick = 'daily_warm_up_question_continue_click';
  static const String dailyWarmUpExitClick = 'daily_warm_up_exit_click';
  static const String dailyWarmUpCompleteView = 'daily_warm_up_complete_view';
  static const String dailyWarmUpStartLessonClick = 'daily_warm_up_start_lesson_click';
  static const String dailyWarmUpExploreMoreClick = 'daily_warm_up_explore_more_click';
  static const String dailyWarmUpRouteFailure = 'daily_warm_up_route_failure';
  static const String homeWidgetTap = 'home_widget_tap';
  static const String homeWidgetDeeplinkSuccess = 'home_widget_deeplink_success';
  static const String homeWidgetDeeplinkFailure = 'home_widget_deeplink_failure';
  static const String homeContinueCardClick = 'home_continue_card_click';
  static const String homeContinueSwipe = 'home_continue_swipe';
  static const String homeExploreClick = 'home_explore_click';
  static const String homeHabitClick = 'home_habit_click';
  static const String homeRcmSeeallClick = 'home_rcm_seeall_click';
  static const String homeRcmCardClick = 'home_rcm_card_click';
  static const String homeRcmSwipe = 'home_rcm_swipe';
  static const String alertUpdateView = 'alert_update_view';
  static const String alertUpdateConfirm = 'alert_update_confirm';
  static const String inappSurveyClick = 'inapp_survey_click';
  static const String inappSurveySubmit = 'inapp_survey_submit';

  //* Change background (theme) events
  static const String themeChangeClick = 'theme_change_click';
  static const String themeChangeScrView = 'theme_change_scr_view';
  static const String themeChangeExit = 'theme_change_exit';
  static const String themeChangeUpload = 'theme_change_upload';
  static const String themeChangeSelect = 'theme_change_select';

  //* Course selection events
  static const String courseSelectAllCourseView = 'course_select_all_course_view';
  static const String courseSelectMyCourseView = 'course_select_my_course_view';
  static const String courseSelectCategorySlide = 'course_select_category_slide';
  static const String courseSelectCategoryClick = 'course_select_category_click';
  static const String courseSelectFirstCourseClick = 'course_select_1stcourse_click';
  static const String courseSelectCourseClick = 'course_select_course_click';
  static const String courseSelectExit = 'course_select_exit';
  static const String courseSelectAllCourseScroll = 'course_select_all_course_scroll';

  //* Explore events
  static const String exploreScrView = 'explore_scr_view';
  static const String exploreCatChipClick = 'explore_cat_chip_click';
  static const String exploreCourseClick = 'explore_course_click';
  static const String exploreCatViewmore = 'explore_cat_viewmore';
  static const String exploreCatlistScrView = 'explore_catlist_scr_view';
  static const String exploreCatlistBackClick = 'explore_catlist_back_click';
  static const String courseComingsoonView = 'course_comingsoon_view';
  static const String exploreSearchClick = 'explore_search_click';
  static const String exploreRecentClearClick = 'explore_recent_clear_click';
  static const String exploreSearchClearClick = 'explore_search_clear_click';
  static const String exploreSearchResultView = 'explore_search_result_view';
  static const String exploreSearchNoresultView = 'explore_search_noresult_view';
  static const String exploreImportClick = 'explore_import_click';

  //* Course events
  static const String popupLearningIntroScrView = 'popup_learning_intro_scr_view';
  static const String popupLearningIntroContinue = 'popup_learning_intro_continue';
  static const String popupLearningIntroSwipe = 'popup_learning_intro_swipe';
  static const String roadmapScrView = 'roadmap_scr_view';
  static const String roadmapItemClick = 'roadmap_item_click';
  static const String popupItemImp = 'popup_item_imp';
  static const String popupItemClick = 'popup_item_click';
  static const String roadmapItemScroll = 'roadmap_item_scroll';
  // Learning-flow rename (spec): fired string aligned to 'roadmap_quickstart_click'.
  static const String roadmapQuickLearningClick = 'roadmap_quickstart_click';
  static const String howItWorkScrView = 'how_it_work_scr_view';
  static const String outputPracticePopupView = 'output_practice_popup_view';
  static const String outputPracticePopupClose = 'output_practice_popup_close';
  static const String outputPracticeStartClick = 'output_practice_start_click';
  static const String outputPracticeScrView = 'output_practice_scr_view';
  static const String outputPracticeOptionClick = 'output_practice_option_click';
  static const String outputPracticeSendClick = 'output_practice_send_click';
  static const String outputPracticeExitClick = 'output_practice_exit_click';
  static const String videoLessonPopupView = 'video_lesson_popup_view';
  static const String videoLessonPopupClose = 'video_keypoint_exit_click';
  static const String videoLessonStartClick = 'video_start_click';
  static const String videoLessonScrView = 'video_play_scr_view';
  static const String videoLessonExitClick = 'video_exit_click';
  static const String videoLessonPlayClick = 'video_lesson_play_click';
  static const String videoLessonPauseClick = 'video_pause_click';
  static const String videoLessonSeek = 'video_seek_click';
  static const String videoLessonPlayerInit = 'video_lesson_player_init';
  static const String videoLessonNotesView = 'video_lesson_notes_view';
  static const String videoLessonAddNoteClick = 'video_lesson_add_note_click';
  static const String videoLessonNoteSaveClick = 'video_note_save_click';
  static const String videoLessonNoteEditClick = 'video_lesson_note_edit_click';
  static const String videoLessonNoteDeleteClick = 'video_lesson_note_delete_click';
  static const String videoLessonSummaryView = 'video_summary_open_click';
  static const String videoLessonSummaryScroll = 'video_lesson_summary_scroll';
  static const String videoLessonSummaryClose = 'video_lesson_summary_close';
  static const String videoLessonShareClick = 'video_lesson_share_click';
  static const String videoLessonQuizView = 'video_lesson_quiz_view';
  static const String videoLessonQuizCheck = 'video_question_check_click';
  static const String videoLessonQuizResultView = 'video_lesson_quiz_result_view';
  static const String videoLessonQuizContinue = 'video_question_cont_click';
  static const String videoLessonCompleteView = 'video_lesson_complete_view';
  static const String videoLessonMarkCompleteClick = 'video_complete_click';

  //* Keypoint audio events
  // NOTE (learning-flow spec alignment): several strings below were renamed to
  // the LEARNING spec. Constant NAMES keep the keypointAudio* scheme so call
  // sites don't churn; only the fired VALUES changed. Verified learning-only.
  static const String keypointAudioPopupView = 'keypoint_intro_scr_view';
  static const String keypointAudioPopupReadClick = 'audio_keypoint_read_click';
  static const String keypointAudioPopupListenClick = 'audio_keypoint_listen_click';
  static const String keypointAudioPopupExitClick = 'keypoint_intro_close';
  static const String keypointAudioScreenView = 'keypoint_listen_scr_view';
  static const String keypointAudioModeSwitch = 'keypoint_audio_mode_switch';
  static const String keypointAudioToTextSwitchClick = 'audio_to_text_switch_click';
  static const String keypointTextToAudioSwitchClick = 'text_to_audio_switch_click';
  static const String keypointAudioPlayClick = 'keypoint_audio_play_click';
  static const String keypointAudioPauseClick = 'audio_pause_click';
  static const String keypointAudioExitClick = 'audio_exit_click';
  static const String keypointAudioSeekBackClick = 'keypoint_listen_rewind_click';
  static const String keypointAudioSeekForwardClick = 'keypoint_listen_forward_click';
  static const String keypointAudioSpeedOpen = 'keypoint_listen_speed_open';
  static const String keypointAudioSpeedSelect = 'keypoint_listen_speed_set';
  static const String keypointAudioCompleteView = 'keypoint_audio_complete_view';
  static const String keypointAudioCompleteContinueClick = 'audio_complete_continue_click';

  //* Keypoint events
  static const String keypointTheoryScroll = 'keypoint_theory_scroll';
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
  static const String keypointExerciseCheckClick = 'keypoint_exs_check_click';
  static const String keypointExerciseResultView = 'keypoint_exs_result_view';
  static const String keypointExerciseExplainClick = 'keypoint_exercise_explain_click';
  static const String keypointExerciseExplainView = 'keypoint_exercise_explain_view';
  static const String keypointExerciseExplainReplay = 'keypoint_exercise_explain_replay';
  static const String keypointExerciseScroll = 'keypoint_exercise_scroll';
  static const String keypointExerciseContinue = 'keypoint_exercise_continue';
  static const String keypointExerciseExplainClose = 'keypoint_exercise_explain_close';
  static const String keypointFinishScrView = 'keypoint_complete_scr_view';
  static const String keypointBadgeUpdateScrView = 'keypoint_badge_update_scr_view';
  static const String keypointFinishComplete = 'keypoint_complete_click';
  static const String lessonFinishScrView = 'lesson_finish_scr_view';
  static const String keypointExitClick = 'keypoint_read_exit_click';
  static const String keypointExitPopupView = 'keypoint_exit_popup_view';
  static const String keypointExitPopupClick = 'keypoint_exit_popup_click';
  static const String keypointPopupNavView = 'keypoint_popup_nav_view';
  static const String keypointPopupNavContinue = 'keypoint_popup_nav_continue';
  static const String completionStreakSuccessView = 'completion_streak_success_view';
  static const String completionStreakSuccessCommitClick = 'completion_streak_success_commit_click';

  //* Sheet tab "new" (2026-08): keypoint recap/locked, complete-screen split,
  //* practice hub + practice quiz. Names must match the sheet exactly.
  static const String keypointRecapTap = 'keypoint_recap_tap';
  static const String keypointLockedScrView = 'keypoint_locked_scr_view';
  static const String keypointLockedPremiumClick = 'keypoint_locked_premium_click';
  static const String keypointPracticeClick = 'keypoint_practice_click';
  static const String keypointCompleteExit = 'keypoint_complete_exit';
  static const String keypointCompleteSkip = 'keypoint_complete_skip';
  static const String practiceHubScrView = 'practice_hub_scr_view';
  static const String practiceModeSelect = 'practice_mode_select';
  static const String practiceHubExit = 'practice_hub_exit';
  static const String pracQuizScrView = 'prac_quiz_scr_view';
  static const String pracQuizCheckClick = 'prac_quiz_check_click';
  static const String pracQuizCompleteScrView = 'prac_quiz_complete_scr_view';
  static const String pracQuizExit = 'prac_quiz_exit';

  //* Learning (roadmap/warmup/keypoint report) events
  static const String roadmapBack = 'roadmap_back';
  static const String roadmapSuggestContent = 'roadmap_suggest_content';
  static const String roadmapSkipSuggestContent = 'roadmap_skip_suggest_content';
  static const String keypointIntroModeSelect = 'keypoint_intro_mode_select';
  static const String keypointReadScrView = 'keypoint_read_scr_view';
  static const String keypointReadScroll = 'keypoint_read_scroll';
  static const String keypointReadContinue = 'keypoint_read_continue';
  static const String keypointListenPlayToggle = 'keypoint_listen_play_toggle';
  static const String keypointExsExplainToggle = 'keypoint_exs_explain_toggle';
  static const String keypointReadMenuOpen = 'keypoint_read_menu_open';
  static const String keypointReportClick = 'keypoint_report_click';
  static const String keypointReportScrView = 'keypoint_report_scr_view';
  static const String keypointReportClose = 'keypoint_report_close';

  //* Keypoint Player overflow menu (…) — mode-aware bottom sheet + its sub-sheets
  //* (Text display / Report an issue). Fired alongside any existing telemetry.
  static const String keypointMenuOpen = 'keypoint_menu_open';
  static const String keypointMenuThemeClick = 'keypoint_menu_theme_click';
  static const String keypointMenuTextdisplayClick = 'keypoint_menu_textdisplay_click';
  static const String keypointMenuReportClick = 'keypoint_menu_report_click';
  static const String keypointMenuBgmusicToggle = 'keypoint_menu_bgmusic_toggle';
  static const String keypointMenuClose = 'keypoint_menu_close';
  static const String menuTextdisplayScrView = 'menu_textdisplay_scr_view';
  static const String menuTextdisplaySizeClick = 'menu_textdisplay_size_click';
  static const String menuTextdisplayFontClick = 'menu_textdisplay_font_click';
  static const String menuTextdisplayClose = 'menu_textdisplay_close';
  static const String menuReportScrView = 'menu_report_scr_view';
  static const String menuReportSubmit = 'menu_report_submit';
  static const String menuReportClose = 'menu_report_close';

  static const String warmupIntroScrView = 'warmup_intro_scr_view';
  static const String warmupIntroStart = 'warmup_intro_start';
  static const String warmupIntroSkip = 'warmup_intro_skip';
  static const String warmupQuizScrView = 'warmup_quiz_scr_view';
  static const String warmupQuizExit = 'warmup_quiz_exit';
  static const String warmupDoneScrView = 'warmup_done_scr_view';
  static const String warmupContinueClick = 'warmup_continue_click';

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

  //* Exit feedback events (sheet tab "9. Exit feedback") — the mid-keypoint
  //* exit "Tell us what happened" popup + its "thanks" popup. Fired alongside
  //* the existing feedback_incomplete_lesson_* telemetry (which stays intact).
  static const String exitFeedbackScrView = 'exit_feedback_scr_view';
  static const String exitFeedbackSendClick = 'exit_feedback_send_click';
  static const String exitFeedbackCloseClick = 'exit_feedback_close_click';
  static const String exitThanksScrView = 'exit_thanks_scr_view';
  static const String exitThanksDoneClick = 'exit_thanks_done_click';

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
  // Spec rename (Language): value aligned to 'settings_lang_scr_view'.
  static const String settingLanguageScrView = 'settings_lang_scr_view';
  static const String settingTermClick = 'setting_term_click';
  // Spec rename: value aligned to 'setting_restore_click' (const name kept so
  // the single call site doesn't churn — matches the onboardV2* convention).
  static const String settingRestorePurcClick = 'setting_restore_click';
  static const String settingLogoutClick = 'setting_logout_click';
  static const String settingPremiumClick = 'setting_premium_click';
  static const String settingNotificationToggleOn = 'setting_notification_toggle_on';
  static const String settingNotificationToggleOff = 'setting_notification_toggle_off';
  // Spec renames (Paywall): const NAMES kept, fired VALUES aligned to the
  // paywall_* spec set.
  static const String premiumScrView = 'paywall_scr_view';
  static const String premiumScroll = 'premium_scroll';
  static const String premiumInforSwipe = 'premium_infor_swipe';
  static const String premiumRestoreClick = 'paywall_restore_click';
  // Sheet tab "new" (2026-08): renamed from paywall_subscribe_click.
  static const String premiumPurchase = 'paywall_upgrade_click';
  static const String premiumScrExit = 'paywall_close_click';
  static const String premiumAllpackPick = 'paywall_plan_click';
  // Spec renames (Achievement badges): value aligned to profile_badge_*.
  static const String settingBadgeClick = 'profile_badge_click';
  static const String settingBadgeSlide = 'setting_badge_slide';
  static const String settingBadgeDetailView = 'profile_badge_scr_view';
  static const String settingBadgeDetailSlide = 'setting_badge_detail_slide';
  static const String settingBadgeGoCourse = 'profile_badge_gocourse';

  //* Paywall screen events
  static const String paywallScrView = 'paywall_scr_view';
  static const String paywallPackageClick = 'paywall_package_click';
  static const String paywallExitClick = 'paywall_exit_click';
  static const String paywallStartPremiumClick = 'paywall_start_premium_click';
  static const String paywallStorePopupDismiss = 'paywall_store_popup_dismiss';

  //* Sheet tab "new" (2026-08): gift popup + 33%-off compact sheet.
  static const String paywallGiftScrView = 'paywall_gift_scr_view';
  static const String paywallGiftOpenClick = 'paywall_gift_open_click';
  static const String paywallOfferScrView = 'paywall_offer_scr_view';
  static const String paywallOfferClaimClick = 'paywall_offer_claim_click';
  static const String paywallOfferCloseClick = 'paywall_offer_close_click';

  //* Habit events
  static const String habitScrView = 'habit_scr_view';
  static const String habitItemOpen = 'habit_item_open';
  static const String habitTaskCheck = 'habit_task_check';
  static const String habitNoteCheckin = 'habit_note_checkin';
  static const String habitNoteClose = 'habit_note_close';
  static const String habitEditOpen = 'habit_edit_open';
  static const String habitEmptyCourseClick = 'habit_empty_course_click';
  static const String habitDetailScrView = 'habit_detail_scr_view';
  static const String habitDetailClose = 'habit_detail_close';
  static const String habitEditScrView = 'habit_edit_scr_view';
  static const String habitEditToggle = 'habit_edit_toggle';
  static const String habitEditClose = 'habit_edit_close';
  static const String habitStartScrView = 'habit_start_scr_view';
  static const String habitStartAdd = 'habit_start_add';
  static const String habitStartSkip = 'habit_start_skip';
  static const String habitAddedScrView = 'habit_added_scr_view';
  static const String habitAddedGoHabit = 'habit_added_go_habit';
  static const String habitAddedContinue = 'habit_added_continue';
  static const String habitSlotsFullScrView = 'habit_slots_full_scr_view';
  static const String habitSlotsUnlimitedClick = 'habit_slots_unlimited_click';
  static const String habitSlotsManageClick = 'habit_slots_manage_click';
  static const String habitSlotsFullClose = 'habit_slots_full_close';
  static const String habitManageScrView = 'habit_manage_scr_view';
  static const String habitManageToggle = 'habit_manage_toggle';
  static const String habitManageConfirm = 'habit_manage_confirm';
  static const String habitManageBack = 'habit_manage_back';

  //* Profile / Setting / Language / Sign in / Paywall (spec alignment) events
  // Profile tab.
  static const String profileScrView = 'profile_scr_view';
  static const String profileSettingsClick = 'profile_settings_click';
  static const String profileAchieveSeeall = 'profile_achieve_seeall';
  static const String profileMycourseClick = 'profile_mycourse_click';
  // Achievement (full list + badge detail sheet).
  static const String profileAchieveScrView = 'profile_achieve_scr_view';
  static const String profileAchieveBackClick = 'profile_achieve_back_click';
  static const String profileBadgeCloseClick = 'profile_badge_close_click';
  // My course library.
  static const String mycourseScrView = 'mycourse_scr_view';
  static const String mycourseBackClick = 'mycourse_back_click';
  static const String profileMycourseCatClick = 'profile_mycourse_cat_click';
  static const String profileMycourseItemClick = 'profile_mycourse_item_click';
  static const String profileMycourseExplore = 'profile_mycourse_explore';
  // Setting screen.
  static const String settingBackClick = 'setting_back_click';
  static const String settingNotifToggle = 'setting_notif_toggle';
  static const String settingHapticToggle = 'setting_haptic_toggle';
  // Language sheet.
  static const String settingsLangBackClick = 'settings_lang_back_click';
  static const String settingsLangSelect = 'settings_lang_select';
  // Sign in.
  static const String signinScrView = 'signin_scr_view';
  static const String signinMethodClick = 'signin_method_click';
  // Paywall (new events not covered by the premium* renames above).
  static const String paywallTermsClick = 'paywall_terms_click';
  static const String paywallPrivacyClick = 'paywall_privacy_click';
  static const String paywallSuccessPopupView = 'paywall_success_popup_view';
  static const String paywallSuccessPopupClick = 'paywall_success_popup_click';

  //* Live activity events
  // `liveScrView` is a "card created" PROXY (fired when the Live Activity is
  // started from Flutter) — NOT a true lock-screen impression, which is
  // native/OS-only. The other two are genuine tap events routed through the
  // shared course-roadmap resume deeplink.
  static const String liveScrView = 'live_scr_view';
  static const String liveResumeTap = 'live_resume_tap';
  static const String liveNudgeTap = 'live_nudge_tap';

  //* Scheduled push notification events
  // Tap on one of the server's scheduled pushes (daily_remind /
  // progress_finish / progress_start / new_course / habit_tracking).
  // Params: noti_type (the server NotificationType), deeplink (destination,
  // tracked even when this build can't route it yet), course_id when carried.
  // `notification_open` is a Firebase-reserved auto-event name — can't be
  // logged manually, hence the custom name.
  static const String notiTap = 'noti_tap';

  //* Subscription events
  static const String subscriptionRenewed = 'subscription_renewed';
  static const String subscriptionCancelled = 'subscription_cancelled';
  static const String subscriptionExpired = 'subscription_expired';
  static const String subscriptionFailed = 'subscription_failed';
  static const String subscriptionCompleted = 'subscription_completed';
}
