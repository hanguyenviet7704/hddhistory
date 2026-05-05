part of '../../onboard_v2.dart';

class OnboardV2Tracking {
  const OnboardV2Tracking._();

  static void trackPageView(OnboardV2PageStep page) {
    track(_viewEvent(page), parameters: {'page': _pageName(page)});
  }

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{
      'onboard_version': 'v2',
      if (parameters != null) ...parameters,
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

  static Map<String, dynamic> skillsetParams(SkillsetEntity skillset, {required int selectedCount}) {
    return {
      'skillset_id': skillset.id,
      'skillset_name': _skillsetTrackingName(skillset),
      'selected_count': selectedCount,
    };
  }

  static Map<String, dynamic> selectedSkillsetParams(OnboardV2SkillsetSelection selection) {
    return {
      'selected_skillset_ids': selection.skillsetIds.join(','),
      'selected_skillset_names': selection.skillsets.map(_skillsetTrackingName).where((name) => name.isNotEmpty).join(','),
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
      OnboardV2PageStep.p4Skillset => TrackingKey.onboardV2P4View,
      OnboardV2PageStep.p5Demo => TrackingKey.onboardV2P5View,
      OnboardV2PageStep.p6Notification => TrackingKey.onboardV2P6View,
      OnboardV2PageStep.p7Recommendation => TrackingKey.onboardV2P7View,
    };
  }

  static String _pageName(OnboardV2PageStep page) {
    return switch (page) {
      OnboardV2PageStep.p1Intro => 'p1_intro',
      OnboardV2PageStep.p2Name => 'p2_name',
      OnboardV2PageStep.p3Age => 'p3_age',
      OnboardV2PageStep.p4Skillset => 'p4_skillset',
      OnboardV2PageStep.p5Demo => 'p5_demo',
      OnboardV2PageStep.p6Notification => 'p6_notification',
      OnboardV2PageStep.p7Recommendation => 'p7_recommendation',
    };
  }

  static String _skillsetTrackingName(SkillsetEntity skillset) {
    final localized = skillset.title.text.trim();
    if (localized.isNotEmpty) return localized;
    if (skillset.title.en.trim().isNotEmpty) return skillset.title.en.trim();
    return skillset.id;
  }
}
