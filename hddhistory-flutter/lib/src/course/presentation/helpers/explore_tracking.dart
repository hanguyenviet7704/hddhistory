part of '../../course.dart';

/// Lightweight analytics helper for the Explore (course) surfaces.
///
/// Mirrors [OnboardV2Tracking]'s safe pattern: fire-and-forget, never throws,
/// swallows all errors so a tracking failure can never break a tap/navigation.
class ExploreTracking {
  const ExploreTracking._();

  /// Fires [eventName] with [parameters]. Null-valued params are dropped.
  /// Safe: try/catch + unawaited + catchError, so it never surfaces an error.
  static void track(String eventName, {Map<String, dynamic>? parameters}) {
    final eventParameters = <String, dynamic>{...?parameters}..removeWhere((_, value) => value == null);
    try {
      final trackingService = AppService.instance.appTrackingService;
      unawaited(trackingService.trackEvent(eventName, parameters: eventParameters).catchError((_) {}));
    } catch (_) {
      return;
    }
  }

  /// Remaps a raw `allCourseSource` value to the `explore_scr_view` spec set
  /// {nav_explore, home_explore, my_course}: any `home_*` → home_explore,
  /// `my_courses_explore_more`/`my_course` → my_course, everything else →
  /// nav_explore (covers `unknown`, `category_courses_back`, deep-links, …).
  static String remapScrViewSource(String? source) {
    final value = source ?? '';
    if (value.startsWith('home')) return 'home_explore';
    if (value == 'my_courses_explore_more' || value == 'my_course') return 'my_course';
    return 'nav_explore';
  }

  /// `course_state` for [course]: coming → new → done → progress → not_start.
  /// [passed]/[total] override the course's own lesson numbers when a
  /// progress-merged count is available (the category list returns passed=0).
  static String courseState(CourseEntity course, {int? passed, int? total}) {
    if (course.isComingSoonNow) return 'coming';
    if (course.isNewNow) return 'new';
    final done = passed ?? course.numberOfLessonPassed;
    final all = total ?? course.numberOfLesson;
    if (all > 0 && done >= all) return 'done';
    if (done > 0 && done < all) return 'progress';
    return 'not_start';
  }

  /// {skill_id, skill_name} for [category].
  static Map<String, dynamic> categoryParams(CategoryEntity category) => {
    'skill_id': category.id,
    'skill_name': category.trackingName,
  };

  /// {course_id, course_name} for [course].
  static Map<String, dynamic> courseParams(CourseEntity course) => {
    'course_id': course.id,
    'course_name': course.trackingName,
  };

  /// {section_type, section_id} for a strip on the Explore tab.
  ///
  /// Replaces [categoryParams] on `explore_course_click`. After the redesign
  /// most tiles belong to no category — a collection is hand-picked across
  /// them — so sending `skill_id` there would have reported an empty category
  /// for nearly every tap on the tab, and the existing category breakdown would
  /// have gone quietly wrong rather than obviously missing.
  ///
  /// `section_id` is the collection's id, and empty for the computed strips:
  /// weeklyTop and becauseYou are one section each, so their type identifies
  /// them.
  static Map<String, dynamic> sectionParams(ExploreSectionEntity section) => {
    'section_type': section.type.name,
    'section_id': section.id,
  };
}
