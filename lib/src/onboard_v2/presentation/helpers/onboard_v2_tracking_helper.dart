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

  /// Sets Firebase Analytics user properties. The tracking sheet marks `age`,
  /// `path_selected`, `habit_struggle`, `noti_allowed` and `first_course` as
  /// User Properties (not just event params), so they are also persisted here.
  /// Empty/null values are dropped so a partial step never clears a property.
  static void setUserProperties(Map<String, dynamic> properties) {
    final props = <String, dynamic>{...properties}..removeWhere((_, value) => value == null || (value is String && value.trim().isEmpty));
    if (props.isEmpty) return;
    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.setUserProperties(props).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// Câu trả lời của 3 câu hỏi, gửi kèm mọi sự kiện "Tiếp tục". Onboarding v3
  /// gửi MÃ taxonomy (`CX`, `CX-1`) chứ không còn enum.
  static Map<String, dynamic> selectionParams(OnboardV2State s) => {
    'branch_codes': s.selectedBranchCodes,
    'package_codes': s.selectedPackageCodes,
    'desire_code': s.selectedDesireCode,
  };

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

  /// Sự kiện view giữ nguyên tên trên sheet dù thứ tự bước đã đổi: nhánh dùng
  /// lại hàng "paths", vấn đề dùng lại "symptom", mong muốn + cách dạy dùng lại
  /// "infor", nhắc học dùng lại "notif", loading dùng lại "course".
  static String _viewEvent(OnboardV2PageStep page) {
    return switch (page) {
      OnboardV2PageStep.p1Intro => TrackingKey.onboardV2P1View,
      OnboardV2PageStep.p2Name => TrackingKey.onboardV2P2View,
      OnboardV2PageStep.p3Age => TrackingKey.onboardV2P3View,
      OnboardV2PageStep.p4Branches => TrackingKey.onboardV2P5View,
      OnboardV2PageStep.p5Problems => TrackingKey.onboardV2P7View,
      OnboardV2PageStep.p6Desire => TrackingKey.onboardV2P6View,
      OnboardV2PageStep.p7How => TrackingKey.onboardV2P6View,
      OnboardV2PageStep.p8Reminder => TrackingKey.onboardV2P4View,
      OnboardV2PageStep.p9Loading => TrackingKey.onboardV2P8View,
      OnboardV2PageStep.p10Result => TrackingKey.onboardV2P10View,
      OnboardV2PageStep.p11Theme => TrackingKey.onboardV2P9View,
    };
  }

  static String _pageName(OnboardV2PageStep page) {
    return switch (page) {
      OnboardV2PageStep.p1Intro => 'p1_intro',
      OnboardV2PageStep.p2Name => 'p2_name',
      OnboardV2PageStep.p3Age => 'p3_age',
      OnboardV2PageStep.p4Branches => 'p4_branches',
      OnboardV2PageStep.p5Problems => 'p5_problems',
      OnboardV2PageStep.p6Desire => 'p6_desire',
      OnboardV2PageStep.p7How => 'p7_how',
      OnboardV2PageStep.p8Reminder => 'p8_reminder',
      OnboardV2PageStep.p9Loading => 'p9_loading',
      OnboardV2PageStep.p10Result => 'p10_result',
      OnboardV2PageStep.p11Theme => 'p11_theme',
    };
  }
}
