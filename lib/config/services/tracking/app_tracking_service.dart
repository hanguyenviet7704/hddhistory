part of '../services.dart';

@LazySingleton(as: ITrackingService)
final class AppTrackingService extends ITrackingService {
  final BaseTrackingService _appTrackingService;
  AppTrackingService(@Named(DIKey.firebaseAnalyticsService) this._appTrackingService);

  @override
  Future<void> initialize() async {
    _appTrackingService.initialize();
  }

  @override
  Future<void> trackScreenView(String screenName) async {
    _appTrackingService.trackScreenView(screenName);
  }

  @override
  Future<void> trackEvent(String eventName, {Map<String, dynamic>? parameters}) async {
    _appTrackingService.trackEvent(eventName, parameters: parameters);
  }

  @override
  Future<void> trackError(dynamic exception, {StackTrace? stackTrace, Map<String, dynamic>? context, String? errorType}) async {
    _appTrackingService.trackError(exception, stackTrace: stackTrace, context: context, errorType: errorType);
  }

  @override
  Future<void> trackBreadcrumb(String message, {Map<String, dynamic>? data, String? category}) async {
    _appTrackingService.addBreadcrumb(message, data: data, category: category);
  }

  String _joinTrackingValues(List<String> values) {
    return values.where((value) => value.isNotEmpty).join(',');
  }

  Map<String, dynamic> _courseParams(CourseTrackingData trackingData) {
    return {
      'skill_name': trackingData.skillset.trackingName,
      'skill_id': trackingData.skillset.id,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
    };
  }

  Map<String, dynamic> _courseLessonParams(CourseLessonTrackingData trackingData) {
    return {
      ..._courseParams(trackingData),
      'lesson_id': trackingData.lesson.id,
      'lesson_name': trackingData.lesson.trackingName,
    };
  }

  Map<String, dynamic> _keypointParams(KeypointTrackingData trackingData) {
    return {
      'skill_name': trackingData.skillset.trackingName,
      'skill_id': trackingData.skillset.id,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
      'lesson_id': trackingData.lesson.id,
      'lesson_name': trackingData.lesson.trackingName,
      'keypoint_id': trackingData.keypoint.id,
      'keypoint_name': trackingData.keypoint.trackingName,
    };
  }

  Map<String, dynamic> _keypointAudioParams(
    KeypointTrackingData trackingData, {
    String? mode,
    String? entryPoint,
    double? speed,
    int? audioPosition,
    int? seekFromSecond,
    int? seekToSecond,
  }) {
    return {
      ..._keypointParams(trackingData),
      ..._optionalStringParam('mode', mode),
      ..._optionalStringParam('entry_point', entryPoint),
      ..._optionalParam('speed', speed),
      ..._optionalParam('speed_value', speed),
      ..._optionalParam('audio_position', audioPosition),
      ..._optionalParam('seek_from_second', seekFromSecond),
      ..._optionalParam('seek_to_second', seekToSecond),
    };
  }

  Map<String, dynamic> _roleplayParams(RoleplayTrackingData trackingData) {
    final roleplayId = trackingData.learningItem.id.isNotEmpty ? trackingData.learningItem.id : trackingData.lesson.learningItemId;
    final roleplayName = trackingData.learningItem.title.en.isNotEmpty ? trackingData.learningItem.title.en : trackingData.lesson.trackingName;
    return {
      'skill_name': trackingData.skillset.trackingName,
      'skill_id': trackingData.skillset.id,
      'course_id': trackingData.course.id,
      'course_name': trackingData.course.trackingName,
      'roleplay_id': roleplayId,
      'roleplay_name': roleplayName,
    };
  }

  Map<String, dynamic> _feedbackParams(CourseTrackingData trackingData, {required String source}) {
    return {
      ..._courseParams(trackingData),
      'source': source,
    };
  }

  Map<String, dynamic> _outputPracticeParams(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    String? conversationId,
    String? language,
  }) {
    return {
      ..._courseLessonParams(trackingData),
      'section_id': sectionId,
      if (conversationId != null && conversationId.isNotEmpty) 'conversation_id': conversationId,
      if (language != null && language.isNotEmpty) 'language': language,
    };
  }

  Map<String, dynamic> _videoLessonParams(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    int? atSecond,
    String? questionId,
    String? noteId,
    String? noteMode,
    int? seekFromSecond,
    int? seekToSecond,
    int? seekLatencyMs,
    int? timeToFirstFrameMs,
    int? videoPosition,
    bool? isCorrect,
    String? initStatus,
    String? warmupState,
  }) {
    final keypoint = trackingData.lesson.firstKeypoint;
    return {
      ..._courseLessonParams(trackingData),
      'keypoint_id': keypoint.id,
      'keypoint_name': keypoint.trackingName,
      'node_id': nodeId,
      'lesson_type': LessonType.video.trackingName,
      ..._optionalParam('at_second', atSecond),
      ..._optionalParam('video_position', videoPosition),
      ..._optionalStringParam('question_id', questionId),
      ..._optionalStringParam('note_id', noteId),
      ..._optionalStringParam('note_mode', noteMode),
      ..._optionalParam('seek_from_second', seekFromSecond),
      ..._optionalParam('seek_to_second', seekToSecond),
      ..._optionalParam('seek_latency_ms', seekLatencyMs),
      ..._optionalParam('time_to_first_frame_ms', timeToFirstFrameMs),
      ..._optionalParam('is_correct', isCorrect),
      ..._optionalStringParam('init_status', initStatus),
      ..._optionalStringParam('warmup_state', warmupState),
    };
  }

  Map<String, dynamic> _optionalParam(String key, Object? value) {
    if (value == null) return const {};
    return {key: value};
  }

  Map<String, dynamic> _optionalStringParam(String key, String? value) {
    if (value == null || value.isEmpty) return const {};
    return {key: value};
  }

  Future<void> _trackSafely(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {}
  }

  Map<String, dynamic> _inAppSurveyParams({
    required String source,
    String? step,
    String? branchId,
    int? branchIndex,
    List<String>? selectedOptionIds,
    bool? feedbackEmpty,
    String? errorType,
  }) {
    final optionIds = selectedOptionIds ?? const <String>[];
    return {
      'source': source,
      ..._optionalStringParam('step', step),
      ..._optionalStringParam('branch_id', branchId),
      ..._optionalParam('branch_index', branchIndex),
      'selected_option_ids': optionIds,
      'selected_option_count': optionIds.length,
      ..._optionalParam('feedback_empty', feedbackEmpty),
      ..._optionalStringParam('error_type', errorType),
    };
  }

  Map<String, dynamic> _dailyWarmUpEntityParams({
    required String source,
    required String courseId,
    required String suggestedCourseId,
    required String lessonId,
    required String keypointId,
    required String shownDate,
  }) {
    return {
      'source': source,
      'course_id': courseId,
      'suggested_course_id': suggestedCourseId,
      'lesson_id': lessonId,
      'keypoint_id': keypointId,
      'shown_date': shownDate,
    };
  }

  Map<String, dynamic> _dailyWarmUpQuestionParams({
    required String questionId,
    required int questionIndex,
    required String questionType,
    required String questionForm,
  }) {
    return {
      'question_id': questionId,
      'question_index': questionIndex,
      'question_type': questionType,
      'question_form': questionForm,
    };
  }

  Map<String, dynamic> _premiumParams() {
    try {
      final cubit = AppDI.injector.get<IapCubit>();
      final entryPoint = cubit.paywallEntryPoint;
      final strategy = cubit.state.resolvedPaywallStrategy;
      final params = <String, dynamic>{
        'source': resolvePremiumTrackingSource(entryPoint),
        'paywall_auto_open': entryPoint == PaywallEntryPoint.autoOpen,
      };
      if (strategy != null && strategy.isValid) {
        params['paywall_strategy_type'] = strategy.strategyType.name;
        params['paywall_segment'] = strategy.segment.name;
        if (strategy.campaignId.isNotEmpty) params['paywall_campaign_id'] = strategy.campaignId;
        if (strategy.impressionNumber != null) params['paywall_impression_number'] = strategy.impressionNumber;
      }
      return params;
    } catch (_) {
      return {};
    }
  }

  @visibleForTesting
  String resolvePremiumTrackingSource(PaywallEntryPoint entryPoint) {
    switch (entryPoint) {
      case PaywallEntryPoint.autoOpen:
        return 'auto_open';
      case PaywallEntryPoint.courseRoadmap:
        return 'course_roadmap';
      case PaywallEntryPoint.settingPre:
      case PaywallEntryPoint.profile:
      case PaywallEntryPoint.manageSubscription:
      case PaywallEntryPoint.other:
        return 'setting_pre';
    }
  }

  Map<String, dynamic> _courseParamsForPaywall() {
    try {
      final iapCubit = AppDI.injector.get<IapCubit>();
      if (iapCubit.paywallEntryPoint != PaywallEntryPoint.courseRoadmap) return {};
      final trackingData = iapCubit.paywallCourseTrackingData;
      if (trackingData == null) return {};
      final skillset = trackingData.skillset;
      final course = trackingData.course;
      if (skillset.id.isEmpty || course.id.isEmpty) return {};
      return {
        'skill_id': skillset.id,
        'skill_name': skillset.trackingName,
        'course_id': course.id,
        'course_name': course.trackingName,
      };
    } catch (_) {
      return {};
    }
  }

  //* Splash & Onboarding events
  @override
  Future<void> trackSplashScrView({String? userId}) async {
    _appTrackingService.trackEvent(
      TrackingKey.splashScrView,
      parameters: {
        if (userId != null && userId.isNotEmpty) 'user_id': userId,
      },
    );
  }

  @override
  Future<void> trackObdIntro1ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro1ScrView);
  }

  @override
  Future<void> trackObdIntro1Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro1Continue);
  }

  @override
  Future<void> trackObdIntro2ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro2ScrView);
  }

  @override
  Future<void> trackObdIntro2Click() async {
    _appTrackingService.trackEvent(TrackingKey.obdIntro2Click);
  }

  @override
  Future<void> trackObdLanguagePopupView(String source) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLanguagePopupView,
      parameters: {
        'source': source,
      },
    );
  }

  @override
  Future<void> trackObdLanguageClick(String language) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLanguageClick,
      parameters: {
        'language': language,
      },
    );
  }

  @override
  Future<void> trackObdNameScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameScrView);
  }

  @override
  Future<void> trackObdNameClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameClick);
  }

  @override
  Future<void> trackObdNameContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdNameContinue);
  }

  @override
  Future<void> trackObdWelcomeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdWelcomeScrView);
  }

  @override
  Future<void> trackObdWelcomeContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdWelcomeContinue);
  }

  @override
  Future<void> trackObdAgeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeScrView);
  }

  @override
  Future<void> trackObdAgeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeClick);
  }

  @override
  Future<void> trackObdAgeContinue(String age) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdAgeContinue,
      parameters: {
        'age': age,
      },
    );
  }

  @override
  Future<void> trackObdAgeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdAgeBack);
  }

  @override
  Future<void> trackObdGenderScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderScrView);
  }

  @override
  Future<void> trackObdGenderClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderClick);
  }

  @override
  Future<void> trackObdGenderContinue(String gender) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdGenderContinue,
      parameters: {
        'gender': gender,
      },
    );
  }

  @override
  Future<void> trackObdGenderBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdGenderBack);
  }

  @override
  Future<void> trackObdLearningGoalScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalScrView);
  }

  @override
  Future<void> trackObdLearningGoalClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalClick);
  }

  @override
  Future<void> trackObdLearningGoalContinue(String learningGoal) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLearningGoalContinue,
      parameters: {
        'learning_goal': learningGoal,
      },
    );
  }

  @override
  Future<void> trackObdLearningGoalBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningGoalBack);
  }

  @override
  Future<void> trackObdSkillsetScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetScrView);
  }

  @override
  Future<void> trackObdSkillsetClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetClick);
  }

  @override
  Future<void> trackObdSkillsetContinue(List<String> skillsets) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdSkillsetContinue,
      parameters: {
        'skillset': _joinTrackingValues(skillsets),
      },
    );
  }

  @override
  Future<void> trackObdSkillsetBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdSkillsetBack);
  }

  @override
  Future<void> trackObdMotivation1ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation1ScrView);
  }

  @override
  Future<void> trackObdMotivation1Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation1Continue);
  }

  @override
  Future<void> trackObdStrugglesScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesScrView);
  }

  @override
  Future<void> trackObdStrugglesClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesClick);
  }

  @override
  Future<void> trackObdStrugglesContinue(List<String> struggles) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdStrugglesContinue,
      parameters: {
        'struggles': _joinTrackingValues(struggles),
      },
    );
  }

  @override
  Future<void> trackObdStrugglesBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdStrugglesBack);
  }

  @override
  Future<void> trackObdMotivation2ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation2ScrView);
  }

  @override
  Future<void> trackObdMotivation2Continue() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation2Continue);
  }

  @override
  Future<void> trackObdHowToLearnScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnScrView);
  }

  @override
  Future<void> trackObdHowToLearnSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnSwipe);
  }

  @override
  Future<void> trackObdHowToLearnContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnContinue);
  }

  @override
  Future<void> trackObdHowToLearnBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdHowToLearnBack);
  }

  @override
  Future<void> trackObdFeedbackScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackScrView);
  }

  @override
  Future<void> trackObdFeedbackSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackSwipe);
  }

  @override
  Future<void> trackObdFeedbackContinue() async {
    _appTrackingService.trackEvent(TrackingKey.obdFeedbackContinue);
  }

  @override
  Future<void> trackObdDailyTimeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeScrView);
  }

  @override
  Future<void> trackObdDailyTimeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeClick);
  }

  @override
  Future<void> trackObdDailyTimeContinue(String dailyTime) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdDailyTimeContinue,
      parameters: {
        'daily_time': dailyTime,
      },
    );
  }

  @override
  Future<void> trackObdDailyTimeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdDailyTimeBack);
  }

  @override
  Future<void> trackObdLearningTimeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeScrView);
  }

  @override
  Future<void> trackObdLearningTimeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeClick);
  }

  @override
  Future<void> trackObdLearningTimeContinue(String learningTime) async {
    _appTrackingService.trackEvent(
      TrackingKey.obdLearningTimeContinue,
      parameters: {
        'learning_time': learningTime,
      },
    );
  }

  @override
  Future<void> trackObdLearningTimeBack() async {
    _appTrackingService.trackEvent(TrackingKey.obdLearningTimeBack);
  }

  @override
  Future<void> trackObdMotivation3ScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation3ScrView);
  }

  @override
  Future<void> trackObdMotivation3Click() async {
    _appTrackingService.trackEvent(TrackingKey.obdMotivation3Click);
  }

  @override
  Future<void> trackObdCompleteScrView() async {
    _appTrackingService.trackEvent(TrackingKey.obdCompleteScrView);
  }

  @override
  Future<void> trackObdCompleteClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdCompleteClick);
  }

  @override
  Future<void> trackObdNotificationGateView() async {
    _appTrackingService.trackEvent(TrackingKey.obdNotificationGateView);
  }

  @override
  Future<void> trackObdNotificationNotifyMeClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdNotificationNotifyMeClick);
  }

  @override
  Future<void> trackObdNotificationMaybeLaterClick() async {
    _appTrackingService.trackEvent(TrackingKey.obdNotificationMaybeLaterClick);
  }

  //* Home events
  @override
  Future<void> trackHomeScrView() async {
    _appTrackingService.trackEvent(TrackingKey.homeScrView);
  }

  @override
  Future<void> trackHomeTabSwitch(String tabType) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeTabSwitch,
      parameters: {
        'tab_type': tabType,
      },
    );
  }

  @override
  Future<void> trackHomeSkillClick(SkillsetEntity skillset) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeSkillClick,
      parameters: {
        'skill_name': skillset.trackingName,
      },
    );
  }

  @override
  Future<void> trackHomeStreakChipClick({required int currentStreak}) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeStreakChipClick,
      parameters: {
        'current_streak': currentStreak,
      },
    );
  }

  @override
  Future<void> trackHomeStreakPopupView({required int currentStreak}) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeStreakPopupView,
      parameters: {
        'current_streak': currentStreak,
      },
    );
  }

  @override
  Future<void> trackHomeStreakPopupClose({required int currentStreak}) async {
    _appTrackingService.trackEvent(
      TrackingKey.homeStreakPopupClose,
      parameters: {
        'current_streak': currentStreak,
      },
    );
  }

  @override
  Future<void> trackInAppSurveyEntryView({required String source}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyEntryView,
        parameters: _inAppSurveyParams(source: source, step: 'p1'),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyEntryClick({required String source}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyEntryClick,
        parameters: _inAppSurveyParams(source: source, step: 'p1'),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyPopupView({required String source, required String step}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyPopupView,
        parameters: _inAppSurveyParams(source: source, step: step),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyPopupClose({required String source, required String step}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyPopupClose,
        parameters: _inAppSurveyParams(source: source, step: step),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyEmojiClick({required String source, required String branchId, required int branchIndex}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyEmojiClick,
        parameters: _inAppSurveyParams(source: source, step: 'p2', branchId: branchId, branchIndex: branchIndex),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyClosedQuestionView({required String source, required String branchId, required int branchIndex}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyClosedQuestionView,
        parameters: _inAppSurveyParams(source: source, step: 'p3', branchId: branchId, branchIndex: branchIndex),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyClosedOptionClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyClosedOptionClick,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p3',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
        ),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyClosedContinueClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyClosedContinueClick,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p3',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
        ),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveyOpenQuestionView({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveyOpenQuestionView,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p4',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
        ),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveySendClick({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveySendClick,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p4',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
          feedbackEmpty: feedbackEmpty,
        ),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveySendSuccess({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveySendSuccess,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p4',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
          feedbackEmpty: feedbackEmpty,
        ),
      ),
    );
  }

  @override
  Future<void> trackInAppSurveySendFailure({
    required String source,
    required String branchId,
    required int branchIndex,
    required List<String> selectedOptionIds,
    required bool feedbackEmpty,
    required String errorType,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.inAppSurveySendFailure,
        parameters: _inAppSurveyParams(
          source: source,
          step: 'p4',
          branchId: branchId,
          branchIndex: branchIndex,
          selectedOptionIds: selectedOptionIds,
          feedbackEmpty: feedbackEmpty,
          errorType: errorType,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpEntryCheck({required String source, required String shownDate}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpEntryCheck,
        parameters: {
          'source': source,
          'shown_date': shownDate,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpSkip({required String source, required String skipReason}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpSkip,
        parameters: {
          'source': source,
          'skip_reason': skipReason,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpP1View({
    required String source,
    required String courseId,
    required String suggestedCourseId,
    required String lessonId,
    required String keypointId,
    required String shownDate,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpP1View,
        parameters: _dailyWarmUpEntityParams(
          source: source,
          courseId: courseId,
          suggestedCourseId: suggestedCourseId,
          lessonId: lessonId,
          keypointId: keypointId,
          shownDate: shownDate,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpStartClick({
    required String source,
    required String courseId,
    required String suggestedCourseId,
    required String lessonId,
    required String keypointId,
    required String shownDate,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpStartClick,
        parameters: _dailyWarmUpEntityParams(
          source: source,
          courseId: courseId,
          suggestedCourseId: suggestedCourseId,
          lessonId: lessonId,
          keypointId: keypointId,
          shownDate: shownDate,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpMaybeLaterClick({
    required String source,
    required String courseId,
    required String suggestedCourseId,
    required String lessonId,
    required String keypointId,
    required String shownDate,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpMaybeLaterClick,
        parameters: _dailyWarmUpEntityParams(
          source: source,
          courseId: courseId,
          suggestedCourseId: suggestedCourseId,
          lessonId: lessonId,
          keypointId: keypointId,
          shownDate: shownDate,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpQuestionView({
    required String questionId,
    required int questionIndex,
    required String questionType,
    required String questionForm,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpQuestionView,
        parameters: _dailyWarmUpQuestionParams(
          questionId: questionId,
          questionIndex: questionIndex,
          questionType: questionType,
          questionForm: questionForm,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpQuestionCheckClick({
    required String questionId,
    required int questionIndex,
    required String questionType,
    required String questionForm,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpQuestionCheckClick,
        parameters: _dailyWarmUpQuestionParams(
          questionId: questionId,
          questionIndex: questionIndex,
          questionType: questionType,
          questionForm: questionForm,
        ),
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpQuestionResultView({
    required String questionId,
    required int questionIndex,
    required String questionType,
    required String questionForm,
    required bool isCorrect,
    required String resultType,
  }) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpQuestionResultView,
        parameters: {
          ..._dailyWarmUpQuestionParams(
            questionId: questionId,
            questionIndex: questionIndex,
            questionType: questionType,
            questionForm: questionForm,
          ),
          'is_correct': isCorrect,
          'result_type': resultType,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpQuestionContinueClick({required String questionId, required int questionIndex}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpQuestionContinueClick,
        parameters: {
          'question_id': questionId,
          'question_index': questionIndex,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpExitClick({required int questionIndex, required int answeredCount}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpExitClick,
        parameters: {
          'question_index': questionIndex,
          'answered_count': answeredCount,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpCompleteView({required int answeredCount, required int correctCount, required String suggestedCourseId}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpCompleteView,
        parameters: {
          'answered_count': answeredCount,
          'correct_count': correctCount,
          'suggested_course_id': suggestedCourseId,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpStartLessonClick({required String suggestedCourseId}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpStartLessonClick,
        parameters: {
          'suggested_course_id': suggestedCourseId,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpExploreMoreClick({required String suggestedCourseId}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpExploreMoreClick,
        parameters: {
          'suggested_course_id': suggestedCourseId,
        },
      ),
    );
  }

  @override
  Future<void> trackDailyWarmUpRouteFailure({required String suggestedCourseId, required String failureStage}) async {
    await _trackSafely(
      () => _appTrackingService.trackEvent(
        TrackingKey.dailyWarmUpRouteFailure,
        parameters: {
          'suggested_course_id': suggestedCourseId,
          'failure_stage': failureStage,
        },
      ),
    );
  }

  @override
  Future<void> trackCourseSelectAllCourseView({required String source}) async {
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectAllCourseView,
      parameters: {
        'source': source,
      },
    );
  }

  @override
  Future<void> trackCourseSelectMyCourseView({required String source}) async {
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectMyCourseView,
      parameters: {
        'source': source,
      },
    );
  }

  @override
  Future<void> trackCourseSelectCategorySlide() async {
    _appTrackingService.trackEvent(TrackingKey.courseSelectCategorySlide);
  }

  @override
  Future<void> trackCourseSelectCategoryClick(
    SkillsetEntity skillset, {
    required bool isRightDirection,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectCategoryClick,
      parameters: {
        'skill_name': skillset.trackingName,
        'skill_id': skillset.id,
        'is_right_direction': isRightDirection ? 'yes' : 'no',
      },
    );
  }

  @override
  Future<void> trackCourseSelectFirstCourseClick(SkillsetEntity skillset, CourseEntity course) async {
    final trackingData = CourseTrackingData(skillset: skillset, course: course);
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectFirstCourseClick,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackCourseSelectCourseClick(
    SkillsetEntity skillset,
    CourseEntity course, {
    required String source,
  }) async {
    final trackingData = CourseTrackingData(skillset: skillset, course: course);
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectCourseClick,
      parameters: {
        ..._courseParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackCourseSelectExit() async {
    _appTrackingService.trackEvent(TrackingKey.courseSelectExit);
  }

  @override
  Future<void> trackCourseSelectAllCourseScroll({required bool isSameCategory}) async {
    _appTrackingService.trackEvent(
      TrackingKey.courseSelectAllCourseScroll,
      parameters: {
        'is_same_category': isSameCategory ? 'yes' : 'no',
      },
    );
  }

  @override
  Future<void> trackPopupLearningIntroScrView(CourseEntity course) async {
    final courseName = course.trackingNameOrText;
    _appTrackingService.trackEvent(
      TrackingKey.popupLearningIntroScrView,
      parameters: {
        'course_id': course.id,
        'course_name': courseName,
      },
    );
  }

  @override
  Future<void> trackPopupLearningIntroContinue() async {
    _appTrackingService.trackEvent(TrackingKey.popupLearningIntroContinue);
  }

  @override
  Future<void> trackPopupLearningIntroSwipe() async {
    _appTrackingService.trackEvent(TrackingKey.popupLearningIntroSwipe);
  }

  @override
  Future<void> trackRoadmapScrView(
    CourseTrackingData trackingData, {
    required String roadmapSource,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapScrView,
      parameters: {
        ..._courseParams(trackingData),
        'roadmap_source': roadmapSource,
      },
    );
  }

  @override
  Future<void> trackRoadmapItemClick(
    CourseLessonTrackingData trackingData, {
    required String itemType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapItemClick,
      parameters: {
        ..._courseParams(trackingData),
        'item_type': itemType,
        'item_id': trackingData.lesson.id,
        'item_name': trackingData.lesson.trackingName,
      },
    );
  }

  @override
  Future<void> trackPopupItemImp(CourseLessonTrackingData trackingData) async {
    final keypoint = trackingData.lesson.firstKeypoint;
    _appTrackingService.trackEvent(
      TrackingKey.popupItemImp,
      parameters: {
        ..._courseLessonParams(trackingData),
        'keypoint_id': keypoint.id,
        'keypoint_name': keypoint.trackingName,
      },
    );
  }

  @override
  Future<void> trackPopupItemClick(CourseLessonTrackingData trackingData) async {
    final keypoint = trackingData.lesson.firstKeypoint;
    _appTrackingService.trackEvent(
      TrackingKey.popupItemClick,
      parameters: {
        ..._courseLessonParams(trackingData),
        'keypoint_id': keypoint.id,
        'keypoint_name': keypoint.trackingName,
      },
    );
  }

  @override
  Future<void> trackRoadmapItemScroll(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapItemScroll,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackRoadmapQuickLearningClick(
    CourseTrackingData trackingData, {
    required String actionType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roadmapQuickLearningClick,
      parameters: {
        ..._courseParams(trackingData),
        'action_type': actionType,
      },
    );
  }

  @override
  Future<void> trackHowItWorkScrView(
    CourseLessonTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.howItWorkScrView,
      parameters: {
        ..._courseLessonParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackOutputPracticePopupView(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticePopupView,
      parameters: _outputPracticeParams(trackingData, sectionId: sectionId),
    );
  }

  @override
  Future<void> trackOutputPracticePopupClose(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticePopupClose,
      parameters: _outputPracticeParams(trackingData, sectionId: sectionId),
    );
  }

  @override
  Future<void> trackOutputPracticeStartClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticeStartClick,
      parameters: _outputPracticeParams(trackingData, sectionId: sectionId),
    );
  }

  @override
  Future<void> trackOutputPracticeScrView(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required String language,
    required String entryState,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticeScrView,
      parameters: {
        ..._outputPracticeParams(
          trackingData,
          sectionId: sectionId,
          conversationId: conversationId,
          language: language,
        ),
        'entry_state': entryState,
      },
    );
  }

  @override
  Future<void> trackOutputPracticeOptionClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required String optionLabel,
    required int optionValue,
    required String inputSource,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticeOptionClick,
      parameters: {
        ..._outputPracticeParams(
          trackingData,
          sectionId: sectionId,
          conversationId: conversationId,
        ),
        'option_label': optionLabel,
        'option_value': optionValue,
        'input_source': inputSource,
      },
    );
  }

  @override
  Future<void> trackOutputPracticeSendClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
    required int messageLength,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticeSendClick,
      parameters: {
        ..._outputPracticeParams(
          trackingData,
          sectionId: sectionId,
          conversationId: conversationId,
        ),
        'message_type': 'text',
        'message_length': messageLength,
      },
    );
  }

  @override
  Future<void> trackOutputPracticeExitClick(
    CourseLessonTrackingData trackingData, {
    required String sectionId,
    required String conversationId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.outputPracticeExitClick,
      parameters: _outputPracticeParams(
        trackingData,
        sectionId: sectionId,
        conversationId: conversationId,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonPopupView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonPopupView,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonPopupClose(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonPopupClose,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonStartClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonStartClick,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonScrView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonScrView,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonExitClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int videoPosition,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonExitClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        videoPosition: videoPosition,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonPlayClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonPlayClick,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonPauseClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int videoPosition,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonPauseClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        videoPosition: videoPosition,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonSeek(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required int seekFromSecond,
    required int seekToSecond,
    int? seekLatencyMs,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonSeek,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        seekFromSecond: seekFromSecond,
        seekToSecond: seekToSecond,
        seekLatencyMs: seekLatencyMs,
        videoPosition: seekToSecond,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonPlayerInit(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String initStatus,
    required String warmupState,
    int? timeToFirstFrameMs,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonPlayerInit,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        initStatus: initStatus,
        warmupState: warmupState,
        timeToFirstFrameMs: timeToFirstFrameMs,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonNotesView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonNotesView,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonAddNoteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteMode,
    required int atSecond,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonAddNoteClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        noteMode: noteMode,
        atSecond: atSecond,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonNoteSaveClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteMode,
    String? noteId,
    required int atSecond,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonNoteSaveClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        noteMode: noteMode,
        noteId: noteId,
        atSecond: atSecond,
        videoPosition: atSecond,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonNoteEditClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteId,
    required String noteMode,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonNoteEditClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        noteId: noteId,
        noteMode: noteMode,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonNoteDeleteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String noteId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonNoteDeleteClick,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        noteId: noteId,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonSummaryView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonSummaryView,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonSummaryScroll(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonSummaryScroll,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonSummaryClose(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonSummaryClose,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonShareClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonShareClick,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonQuizView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonQuizView,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        questionId: questionId,
        atSecond: atSecond,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonQuizCheck(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonQuizCheck,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        questionId: questionId,
        atSecond: atSecond,
        videoPosition: atSecond,
        isCorrect: isCorrect,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonQuizResultView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonQuizResultView,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        questionId: questionId,
        atSecond: atSecond,
        videoPosition: atSecond,
        isCorrect: isCorrect,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonQuizContinue(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
    required String questionId,
    required int atSecond,
    required bool isCorrect,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonQuizContinue,
      parameters: _videoLessonParams(
        trackingData,
        nodeId: nodeId,
        questionId: questionId,
        atSecond: atSecond,
        videoPosition: atSecond,
        isCorrect: isCorrect,
      ),
    );
  }

  @override
  Future<void> trackVideoLessonCompleteView(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonCompleteView,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  @override
  Future<void> trackVideoLessonMarkCompleteClick(
    CourseLessonTrackingData trackingData, {
    required String nodeId,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.videoLessonMarkCompleteClick,
      parameters: _videoLessonParams(trackingData, nodeId: nodeId),
    );
  }

  //* Keypoint audio events
  @override
  Future<void> trackKeypointAudioPopupView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPopupView,
      parameters: _keypointAudioParams(trackingData, entryPoint: 'roadmap_popup'),
    );
  }

  @override
  Future<void> trackKeypointAudioPopupReadClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPopupReadClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.read.routeValue,
        entryPoint: 'roadmap_popup',
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioPopupListenClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPopupListenClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        entryPoint: 'roadmap_popup',
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioPopupExitClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPopupExitClick,
      parameters: _keypointAudioParams(trackingData, entryPoint: 'roadmap_popup'),
    );
  }

  @override
  Future<void> trackKeypointAudioScreenView(
    KeypointTrackingData trackingData, {
    required String mode,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioScreenView,
      parameters: _keypointAudioParams(trackingData, mode: mode),
    );
  }

  @override
  Future<void> trackKeypointAudioModeSwitch(
    KeypointTrackingData trackingData, {
    required String mode,
    required String entryPoint,
    int? audioPosition,
  }) async {
    _appTrackingService.trackEvent(
      mode == LessonEntryMode.read.routeValue ? TrackingKey.keypointAudioToTextSwitchClick : TrackingKey.keypointTextToAudioSwitchClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: mode,
        entryPoint: entryPoint,
        audioPosition: audioPosition,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioPlayClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPlayClick,
      parameters: _keypointAudioParams(trackingData, mode: LessonEntryMode.audio.routeValue),
    );
  }

  @override
  Future<void> trackKeypointAudioPauseClick(
    KeypointTrackingData trackingData, {
    required int audioPosition,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioPauseClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        audioPosition: audioPosition,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioExitClick(
    KeypointTrackingData trackingData, {
    required int audioPosition,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioExitClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        audioPosition: audioPosition,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioSeekBackClick(
    KeypointTrackingData trackingData, {
    required int seekFromSecond,
    required int seekToSecond,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioSeekBackClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        seekFromSecond: seekFromSecond,
        seekToSecond: seekToSecond,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioSeekForwardClick(
    KeypointTrackingData trackingData, {
    required int seekFromSecond,
    required int seekToSecond,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioSeekForwardClick,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        seekFromSecond: seekFromSecond,
        seekToSecond: seekToSecond,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioSpeedOpen(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioSpeedOpen,
      parameters: _keypointAudioParams(trackingData, mode: LessonEntryMode.audio.routeValue),
    );
  }

  @override
  Future<void> trackKeypointAudioSpeedSelect(
    KeypointTrackingData trackingData, {
    required double speed,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioSpeedSelect,
      parameters: _keypointAudioParams(
        trackingData,
        mode: LessonEntryMode.audio.routeValue,
        speed: speed,
      ),
    );
  }

  @override
  Future<void> trackKeypointAudioCompleteView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioCompleteView,
      parameters: _keypointAudioParams(trackingData, mode: LessonEntryMode.audio.routeValue),
    );
  }

  @override
  Future<void> trackKeypointAudioCompleteContinueClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointAudioCompleteContinueClick,
      parameters: _keypointAudioParams(trackingData, mode: LessonEntryMode.audio.routeValue),
    );
  }

  //* Keypoint events
  @override
  Future<void> trackKeypointTheoryScroll(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointTheoryScroll,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointTheoryScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointTheoryScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointTheoryContinueClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointTheoryContinueClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseMultiClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseMultiClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseDrag(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseDrag,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseArrange(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseArrange,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordAnswer(
    KeypointTrackingData trackingData, {
    required String answerType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordAnswer,
      parameters: {
        ..._keypointParams(trackingData),
        'answer_type': answerType,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordTyping(
    KeypointTrackingData trackingData, {
    required String typingInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordTyping,
      parameters: {
        ..._keypointParams(trackingData),
        'typing_interaction': typingInteraction,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseRecordVoice(
    KeypointTrackingData trackingData, {
    required String recordInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseRecordVoice,
      parameters: {
        ..._keypointParams(trackingData),
        'record_interaction': recordInteraction,
      },
    );
  }

  @override
  Future<void> trackKeypointExerciseCheckClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseCheckClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseResultView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseResultView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainReplay(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainReplay,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseScroll(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseScroll,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseContinue(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseContinue,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExerciseExplainClose(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExerciseExplainClose,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointFinishScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointFinishScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointBadgeUpdateScrView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointBadgeUpdateScrView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointFinishComplete(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointFinishComplete,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackLessonFinishScrView(CourseLessonTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.lessonFinishScrView,
      parameters: _courseLessonParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExitClick(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitClick,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExitPopupView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitPopupView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointExitPopupClick(
    KeypointTrackingData trackingData, {
    required String option,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointExitPopupClick,
      parameters: {
        ..._keypointParams(trackingData),
        'popup_option': option,
      },
    );
  }

  @override
  Future<void> trackKeypointPopupNavView(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointPopupNavView,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackKeypointPopupNavContinue(KeypointTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.keypointPopupNavContinue,
      parameters: _keypointParams(trackingData),
    );
  }

  @override
  Future<void> trackCompletionStreakSuccessView({
    required String variant,
    required int currentStreak,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.completionStreakSuccessView,
      parameters: {
        'variant': variant,
        'current_streak': currentStreak,
      },
    );
  }

  @override
  Future<void> trackCompletionStreakSuccessCommitClick({
    required String variant,
    required int currentStreak,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.completionStreakSuccessCommitClick,
      parameters: {
        'variant': variant,
        'current_streak': currentStreak,
      },
    );
  }

  //* Roleplay events
  @override
  Future<void> trackRoleplayInfoScrView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayInfoScrView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayInfoContinueClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayInfoContinueClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayOverviewExitClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayOverviewExitClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayOverviewScroll(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayOverviewScroll,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayMissionsView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayMissionsView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayMissionsScroll(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayMissionsScroll,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayStartClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayStartClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayConvScrView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayConvScrView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayConvExitClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayConvExitClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayConvScroll(
    RoleplayTrackingData trackingData, {
    required String haveQuiz,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayConvScroll,
      parameters: {
        ..._roleplayParams(trackingData),
        'have_quiz': haveQuiz,
      },
    );
  }

  @override
  Future<void> trackRoleplayVoiceInteraction(
    RoleplayTrackingData trackingData, {
    required String voiceAction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayVoiceInteraction,
      parameters: {
        ..._roleplayParams(trackingData),
        'voice_action': voiceAction,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizImp(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizImp,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizExpandedView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizExpandedView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizExpandedClose(
    RoleplayTrackingData trackingData, {
    required String interactType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizExpandedClose,
      parameters: {
        ..._roleplayParams(trackingData),
        'interact_type': interactType,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizSingSelect(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizSingSelect,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizMultiSelect(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizMultiSelect,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizDrag(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizDrag,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizArrange(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizArrange,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizRecordAns(
    RoleplayTrackingData trackingData, {
    required String answerType,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizRecordAns,
      parameters: {
        ..._roleplayParams(trackingData),
        'answer_type': answerType,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizRecordTyping(
    RoleplayTrackingData trackingData, {
    required String typingInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizRecordTyping,
      parameters: {
        ..._roleplayParams(trackingData),
        'typing_interaction': typingInteraction,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizRecordVoice(
    RoleplayTrackingData trackingData, {
    required String recordInteraction,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizRecordVoice,
      parameters: {
        ..._roleplayParams(trackingData),
        'record_interaction': recordInteraction,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizCheck(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizCheck,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizResultView(
    RoleplayTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizResultView,
      parameters: {
        ..._roleplayParams(trackingData),
        'source': source,
      },
    );
  }

  @override
  Future<void> trackRoleplayQuizResultScroll(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizResultScroll,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizContinue(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizContinue,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizReviewReplay(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizReviewReplay,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizCollapsedClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizCollapsedClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayQuizCollapsedReplay(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayQuizCollapsedReplay,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayCompleteClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayCompleteClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayDoneScrView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayDoneScrView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayDoneResultClick(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayDoneResultClick,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayResultScrView(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayResultScrView,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayResultScroll(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayResultScroll,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackRoleplayResultContinue(RoleplayTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.roleplayResultContinue,
      parameters: _roleplayParams(trackingData),
    );
  }

  @override
  Future<void> trackBadgeCompleteScrView({RoleplayTrackingData? trackingData}) async {
    _appTrackingService.trackEvent(
      TrackingKey.badgeCompleteScrView,
      parameters: trackingData == null ? null : _roleplayParams(trackingData),
    );
  }

  //* Feedback events
  @override
  Future<void> trackFeedbackCompleteLessonView(
    CourseTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedbackCompleteLessonView,
      parameters: _feedbackParams(trackingData, source: source),
    );
  }

  @override
  Future<void> trackFeedbackCompleteLessonSend(
    CourseTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedbackCompleteLessonSend,
      parameters: _feedbackParams(trackingData, source: source),
    );
  }

  @override
  Future<void> trackFeedbackIncompleteLessonView(
    CourseTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedbackIncompleteLessonView,
      parameters: _feedbackParams(trackingData, source: source),
    );
  }

  @override
  Future<void> trackFeedbackIncompleteLessonSend(
    CourseTrackingData trackingData, {
    required String source,
  }) async {
    _appTrackingService.trackEvent(
      TrackingKey.feedbackIncompleteLessonSend,
      parameters: _feedbackParams(trackingData, source: source),
    );
  }

  //* Subscription events
  @override
  Future<void> trackSubscriptionRenewed(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionRenewed,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionCancelled(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionCancelled,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionExpired(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionExpired,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionFailed(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionFailed,
      parameters: {
        'package': packageId,
      },
    );
  }

  @override
  Future<void> trackSubscriptionCompleted(String packageId) async {
    _appTrackingService.trackEvent(
      TrackingKey.subscriptionCompleted,
      parameters: {
        'package': packageId,
      },
    );
  }

  //* Profile events
  @override
  Future<void> trackProfileView() async {
    _appTrackingService.trackEvent(TrackingKey.profileView);
  }

  @override
  Future<void> trackProfileLanguageView() async {
    _appTrackingService.trackEvent(TrackingKey.profileLanguageView);
  }

  @override
  Future<void> trackProfileLanguageSelect(String language) async {
    _appTrackingService.trackEvent(TrackingKey.profileLanguageSelect, parameters: {'language': language});
  }

  @override
  Future<void> trackProfileSignoutClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileSignoutClick);
  }

  @override
  Future<void> trackProfileUpgradeClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileUpgradeClick);
  }

  @override
  Future<void> trackProfileSettingClick() async {
    _appTrackingService.trackEvent(TrackingKey.profileSettingClick);
  }

  //* Setting events
  @override
  Future<void> trackSettingScrView() async {
    _appTrackingService.trackEvent(TrackingKey.settingScrView);
  }

  @override
  Future<void> trackSettingScroll() async {
    _appTrackingService.trackEvent(TrackingKey.settingScroll);
  }

  @override
  Future<void> trackSettingProfileClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingProfileClick);
  }

  @override
  Future<void> trackSettingProfileEditClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingProfileEditClick);
  }

  @override
  Future<void> trackSettingProfileDoneClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingProfileDoneClick);
  }

  @override
  Future<void> trackSettingProfileDeleteClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingProfileDeleteClick);
  }

  @override
  Future<void> trackProfileDeleteScrView() async {
    _appTrackingService.trackEvent(TrackingKey.profileDeleteScrView);
  }

  @override
  Future<void> trackProfileDeleteOptionClick(String value) async {
    _appTrackingService.trackEvent(
      TrackingKey.profileDeleteOptionClick,
      parameters: {
        'value': value,
      },
    );
  }

  @override
  Future<void> trackSettingDetailClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingDetailClick);
  }

  @override
  Future<void> trackSettingDetailScrView() async {
    _appTrackingService.trackEvent(TrackingKey.settingDetailScrView);
  }

  @override
  Future<void> trackSettingLanguageClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingLanguageClick);
  }

  @override
  Future<void> trackSettingLanguageScrView(String language) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingLanguageScrView,
      parameters: {
        'language': language,
      },
    );
  }

  @override
  Future<void> trackSettingTermClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingTermClick);
  }

  @override
  Future<void> trackSettingRestorePurchClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingRestorePurcClick);
  }

  @override
  Future<void> trackSettingLogoutClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingLogoutClick);
  }

  @override
  Future<void> trackSettingPremiumClick() async {
    _appTrackingService.trackEvent(TrackingKey.settingPremiumClick);
  }

  @override
  Future<void> trackSettingNotificationToggleOn() async {
    _appTrackingService.trackEvent(TrackingKey.settingNotificationToggleOn);
  }

  @override
  Future<void> trackSettingNotificationToggleOff() async {
    _appTrackingService.trackEvent(TrackingKey.settingNotificationToggleOff);
  }

  @override
  Future<void> trackPremiumScrView() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumScrView,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumScroll() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumScroll,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumInforSwipe() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumInforSwipe,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumRestoreClick() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumRestoreClick,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumPurchase() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumPurchase,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumScrExit() async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumScrExit,
      parameters: {
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackPremiumAllpackPick(String premiumId) async {
    _appTrackingService.trackEvent(
      TrackingKey.premiumAllpackPick,
      parameters: {
        'premium_id': premiumId,
        ..._premiumParams(),
        ..._courseParamsForPaywall(),
      },
    );
  }

  @override
  Future<void> trackSettingBadgeClick(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingBadgeClick,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackSettingBadgeSlide(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingBadgeSlide,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackSettingBadgeDetailView(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingBadgeDetailView,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackSettingBadgeDetailSlide(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingBadgeDetailSlide,
      parameters: _courseParams(trackingData),
    );
  }

  @override
  Future<void> trackSettingBadgeGoCourse(CourseTrackingData trackingData) async {
    _appTrackingService.trackEvent(
      TrackingKey.settingBadgeGoCourse,
      parameters: _courseParams(trackingData),
    );
  }
}
