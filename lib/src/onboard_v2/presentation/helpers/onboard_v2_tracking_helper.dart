part of '../../onboard_v2.dart';

class OnboardV2Tracking {
  const OnboardV2Tracking._();

  static void trackPageView(OnboardV2PageStep page) {
    track(_viewEvent(page), parameters: {'page': _pageName(page)});
  }

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{
      'onboard_version': 'v2',
      ...?parameters,
    }..removeWhere((_, value) => value == null);

    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  static Map<String, dynamic> ageParams(OnboardOptionEntity age) {
    return {
      'selected_age_id': age.id,
      'selected_age_label': OnboardV2AgeTextResolver.resolve(age),
    };
  }

  static Map<String, dynamic> ageSheetParams(OnboardOptionEntity age) {
    final trackingLabel = age.trackingLabel.trim();
    return {
      ...ageParams(age),
      'age': trackingLabel.isNotEmpty ? trackingLabel : OnboardV2AgeTextResolver.resolve(age),
    };
  }

  static Map<String, dynamic> pathParams(OnboardingPath path, {required List<OnboardingPath> selectedPaths}) {
    return {
      'path_id': path.trackingId,
      'path_name': path.title,
      ...selectedPathParams(selectedPaths),
    };
  }

  static Map<String, dynamic> selectedPathParams(List<OnboardingPath> selectedPaths) {
    return {
      'selected_path_ids': selectedPaths.map((path) => path.trackingId).toList(),
      'selected_path_names': selectedPaths.map((path) => path.title).toList(),
      'selected_path_count': selectedPaths.length,
    };
  }

  static Map<String, dynamic> selectedPathSheetParams(List<OnboardingPath> selectedPaths) {
    return {
      ...selectedPathParams(selectedPaths),
      'path_selected': _joinTrackingValues(selectedPaths.map(_pathSheetValue)),
    };
  }

  static Map<String, dynamic> availableSymptomParams(List<OnboardingSymptom> symptoms) {
    return {
      'available_symptom_ids': symptoms.map((symptom) => symptom.trackingId).toList(),
    };
  }

  static Map<String, dynamic> symptomParams(OnboardingSymptom symptom, {required List<OnboardingSymptom> selectedSymptoms}) {
    return {
      'symptom_id': symptom.trackingId,
      'symptom_name': symptom.title,
      ...selectedSymptomParams(selectedSymptoms),
    };
  }

  static Map<String, dynamic> selectedSymptomParams(List<OnboardingSymptom> selectedSymptoms) {
    return {
      'selected_symptom_ids': selectedSymptoms.map((symptom) => symptom.trackingId).toList(),
      'selected_symptom_names': selectedSymptoms.map((symptom) => symptom.title).toList(),
      'selected_symptom_count': selectedSymptoms.length,
    };
  }

  static Map<String, dynamic> selectedSymptomSheetParams(List<OnboardingSymptom> selectedSymptoms) {
    return {
      ...selectedSymptomParams(selectedSymptoms),
      'symptom_selected': _joinTrackingValues(selectedSymptoms.map(_symptomSheetValue)),
    };
  }

  static Map<String, dynamic> pathRelateSheetParams({
    required List<OnboardingPath> selectedPaths,
    required List<OnboardingSymptom> selectedSymptoms,
  }) {
    return {
      ...selectedPathParams(selectedPaths),
      ...selectedSymptomSheetParams(selectedSymptoms),
    };
  }

  static Map<String, dynamic> coursesLoadedParams({
    required List<CourseEntity> courses,
    required List<OnboardingSymptom> selectedSymptoms,
  }) {
    return {
      'course_ids': courses.map((course) => course.id).toList(),
      ...selectedSymptomParams(selectedSymptoms),
    };
  }

  static Map<String, dynamic> courseSelectParams({
    required CourseEntity course,
    required int currentCourseIndex,
  }) {
    return {
      'current_course_index': currentCourseIndex,
      'selected_course_id': course.id,
      'selected_course_name': course.trackingNameOrText,
      'course_id': course.id,
      'course_name': course.trackingNameOrText,
      'is_best_matched': currentCourseIndex == 0 ? 'yes' : 'no',
    };
  }

  static String notificationStatus(OnboardV2NotificationStatus status) {
    return switch (status) {
      OnboardV2NotificationStatus.authorized => 'authorized',
      OnboardV2NotificationStatus.denied => 'denied',
      OnboardV2NotificationStatus.restricted => 'restricted',
      OnboardV2NotificationStatus.permanentlyDenied => 'permanently_denied',
      OnboardV2NotificationStatus.alreadyAuthorized => 'already_authorized',
      OnboardV2NotificationStatus.alreadyDenied => 'already_denied',
      OnboardV2NotificationStatus.unsupported => 'unsupported',
      OnboardV2NotificationStatus.maybeLater => 'maybe_later',
      OnboardV2NotificationStatus.unknown => 'unknown',
    };
  }

  static String exceptionReason(AppException exception) {
    return switch (exception) {
      GenericException() => 'generic',
      ServerException() => 'server',
      ConnectionException() => 'connection',
      DatabaseException() => 'database',
      CacheException() => 'cache',
      NotFoundException() => 'not_found',
      UnauthorizedException() => 'unauthorized',
      InvalidInputException() => 'invalid_input',
      UnexpectedException() => 'unexpected',
      ForbiddenException() => 'forbidden',
      PendingException() => 'pending',
      FromDioException(error: final error) => 'network_${error.type.name}',
      FromGraphQLErrorException() => 'graphql',
    };
  }

  static String _viewEvent(OnboardV2PageStep page) {
    return switch (page) {
      OnboardV2PageStep.p1Intro => TrackingKey.onboardV2P1View,
      OnboardV2PageStep.p2Name => TrackingKey.onboardV2P2View,
      OnboardV2PageStep.p3Age => TrackingKey.onboardV2P3View,
      OnboardV2PageStep.p4Notification => TrackingKey.onboardV2P4View,
      OnboardV2PageStep.p5PathSelection => TrackingKey.onboardV2P5View,
      OnboardV2PageStep.p6PathMap => TrackingKey.onboardV2P6View,
      OnboardV2PageStep.p7Symptoms => TrackingKey.onboardV2P7View,
      OnboardV2PageStep.p8CoursePicker => TrackingKey.onboardV2P8View,
      OnboardV2PageStep.p9Theme => TrackingKey.onboardV2P9View,
    };
  }

  static String _pageName(OnboardV2PageStep page) {
    return switch (page) {
      OnboardV2PageStep.p1Intro => 'p1_intro',
      OnboardV2PageStep.p2Name => 'p2_name',
      OnboardV2PageStep.p3Age => 'p3_age',
      OnboardV2PageStep.p4Notification => 'p4_notification',
      OnboardV2PageStep.p5PathSelection => 'p5_path_selection',
      OnboardV2PageStep.p6PathMap => 'p6_path_map',
      OnboardV2PageStep.p7Symptoms => 'p7_symptoms',
      OnboardV2PageStep.p8CoursePicker => 'p8_course_picker',
      OnboardV2PageStep.p9Theme => 'p9_theme',
    };
  }

  static String _joinTrackingValues(Iterable<String> values) {
    return values.where((value) => value.isNotEmpty).join(',');
  }

  static String _pathSheetValue(OnboardingPath path) {
    return switch (path) {
      OnboardingPath.feelBetter => 'feel_better',
      OnboardingPath.thinkBetter => 'think_better',
      OnboardingPath.workBetter => 'work_better',
      OnboardingPath.connectBetter => 'connect_better',
      OnboardingPath.learnBetter => 'learn_better',
      OnboardingPath.exploreBetter => 'explore_better',
    };
  }

  static String _symptomSheetValue(OnboardingSymptom symptom) {
    return switch (symptom) {
      OnboardingSymptom.motivationDisappears => 'motivation_disappear',
      OnboardingSymptom.lifeFeelsOverwhelming => 'life_overwhelming',
      OnboardingSymptom.endlessScrollingFeelsEmpty => 'scroll_feel_empty',
      OnboardingSymptom.overthinking => 'tend_overthink',
      OnboardingSymptom.tryingToDoTooMuch => 'too_much_at_once',
      OnboardingSymptom.rushedDecisions => 'rush_decisions_regret',
      OnboardingSymptom.difficultyBuildingHabits => 'building_habits_hard',
      OnboardingSymptom.timeSlipsAway => 'time_slips_away',
      OnboardingSymptom.strugglingToBreakBadHabits => 'break_bad_habit',
      OnboardingSymptom.anxietyAroundHardConversations => 'hard_conversations_anxious',
      OnboardingSymptom.wantToListenMoreDeeply => 'listen_more_deeply',
      OnboardingSymptom.regretSayingThingsInEmotion => 'regret_words_emotions',
      OnboardingSymptom.learningDoesNotStick => 'learning_not_stick',
      OnboardingSymptom.forgettingAfterStudying => 'study_forget_morning',
      OnboardingSymptom.losingTrainOfThought => 'losing_train_thought',
      OnboardingSymptom.curiousAboutBody => 'curious_body_works',
      OnboardingSymptom.loveLearningFromGreatMinds => 'learn_from_great_minds',
      OnboardingSymptom.amazedByHumanBody => 'body_surprises_me',
      OnboardingSymptom.unknown => '',
    };
  }
}
