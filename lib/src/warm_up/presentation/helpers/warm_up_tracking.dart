part of '../../warm_up.dart';

/// Analytics helper for the return-refresher warm-up flow (LEARNING spec's
/// `warmup_*` events). Distinct from the Home `daily_warm_up_*` events.
/// Fire-and-forget: tracking never blocks or throws into the UI.
class WarmUpTracking {
  const WarmUpTracking._();

  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    try {
      final service = AppService.instance.appTrackingService;
      unawaited(service.trackEvent(eventName, parameters: parameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// Best-effort course context: course_id from [WarmUpCubit], course_name
  /// resolved through the Home skillsets (falls back to id-only on a miss).
  static Map<String, dynamic> courseParams(String courseId) {
    final id = courseId.trim();
    if (id.isEmpty) return const {};
    try {
      final homeState = AppDI.injector.get<HomeCubit>().state;
      final course = homeState.skillsets.resolveCourseByCourseId(id, fallback: homeState.currentCourse);
      final name = course.trackingNameOrText;
      return {
        'course_id': id,
        if (name.isNotEmpty) 'course_name': name,
      };
    } catch (_) {
      return {'course_id': id};
    }
  }
}
