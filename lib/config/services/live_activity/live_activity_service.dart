part of '../services.dart';

/// Bridges to the native lesson live surface on each platform:
/// - iOS: ActivityKit Live Activity (iOS 16.1+) — `ios/Runner/LiveActivityChannel.swift`.
/// - Android: a promoted ongoing "Live Update" notification (Android 16 / API 36+)
///   — `android/.../LiveActivityChannel.kt`.
///
/// Both native sides internally no-op on OS versions below their minimum
/// (returning without error), and this service no-ops on any other platform, so
/// callers never need to platform- or version-check themselves.
/// Deeplink contract shared with the native Live Activity card and the return
/// nudge. Mirrors the URL the iOS widget emits in
/// `ios/MeupHomeWidgetsExtension/MeupLessonLiveActivityView.swift`:
/// `meup://course-roadmap?courseId=…&source=live_activity`. Unlike the
/// home-widget deeplink this carries no `widgetType`, so it is NOT a
/// HomeWidgetDeeplinkTarget — DeeplinkCubit handles it via its own branch.
abstract final class LiveActivityDeeplink {
  static const String sourceQueryKey = 'source';
  static const String sourceValue = 'live_activity';
  static const String courseIdQueryKey = 'courseId';

  /// The resume deeplink for [courseId], identical to the string the iOS widget
  /// emits — reused by the return nudge so its tap resumes the same course.
  static String resumeUri(String courseId) => 'meup://course-roadmap?courseId=$courseId&source=$sourceValue';
}

@LazySingleton()
class LiveActivityService {
  final MethodChannel _channel = const MethodChannel('meup/live_activity');

  bool get _isSupportedPlatform => Platform.isIOS || Platform.isAndroid;

  /// Course id of the Live Activity we last started and haven't ended, or null
  /// if none is showing. Lets callers (e.g. the roadmap) decide between a fresh
  /// [start] (different/no course) and a cheap [update] (same course, new
  /// progress) so re-entering a roadmap doesn't flicker the card by tearing it
  /// down and re-requesting it.
  String? _activeCourseId;
  String? get activeCourseId => _activeCourseId;

  Future<void> start({
    required String courseId,
    required String courseName,
    required String courseImagePath,
    required double progress,
    required bool isDone,
    required String inLessonLabel,
    required String continueLearningLabel,
    required String resumeLabel,
    required String primaryNudge,
    required String footerNudge,
  }) {
    _activeCourseId = courseId;
    return _invoke('start', {
      'courseId': courseId,
      'courseName': courseName,
      'courseImagePath': courseImagePath,
      'progress': progress,
      'isDone': isDone,
      'inLessonLabel': inLessonLabel,
      'continueLearningLabel': continueLearningLabel,
      'resumeLabel': resumeLabel,
      'primaryNudge': primaryNudge,
      'footerNudge': footerNudge,
    });
  }

  Future<void> update({
    required double progress,
    required bool isDone,
    required String resumeLabel,
    required String primaryNudge,
    required String footerNudge,
  }) => _invoke('update', {
    'progress': progress,
    'isDone': isDone,
    'resumeLabel': resumeLabel,
    'primaryNudge': primaryNudge,
    'footerNudge': footerNudge,
  });

  Future<void> end() {
    _activeCourseId = null;
    return _invoke('end', null);
  }

  Future<void> _invoke(String method, Map<String, dynamic>? args) async {
    if (!_isSupportedPlatform) return;
    try {
      await _channel.invokeMethod(method, args);
    } on PlatformException catch (e) {
      LogDev.warning('[LiveActivityService] $method failed: ${e.message}');
    } on MissingPluginException {
      // Dev-flavor iOS builds without the widget extension linked yet, or a
      // fresh install pre-launch — treat exactly like "not supported".
    }
  }
}
