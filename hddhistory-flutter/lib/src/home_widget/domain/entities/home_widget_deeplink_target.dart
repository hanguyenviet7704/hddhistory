part of '../../home_widget.dart';

class HomeWidgetDeeplinkTarget {
  const HomeWidgetDeeplinkTarget({
    required this.routePath,
    required this.widgetType,
    required this.state,
    required this.courseId,
  });

  final String routePath;
  final HomeWidgetType widgetType;
  final HomeWidgetPayloadState state;
  final String? courseId;

  static const sourceValue = 'home_widget';
  static const sourceQueryKey = 'source';
  static const widgetTypeQueryKey = 'widgetType';
  static const stateQueryKey = 'state';
  static const courseIdQueryKey = 'courseId';

  static HomeWidgetDeeplinkTarget? tryParse(Uri uri) {
    final query = uri.queryParameters;
    if (query[sourceQueryKey] != sourceValue) return null;

    final widgetType = HomeWidgetType.tryFromValue(query[widgetTypeQueryKey] ?? '');
    if (widgetType == null) return null;

    final routePath = resolveDeeplinkRoutePath(uri);
    if (routePath != RoutePath.home && routePath != RoutePath.courseRoadmap) return null;

    final state = HomeWidgetPayloadState.tryFromValue(query[stateQueryKey] ?? '') ?? HomeWidgetPayloadState.ready;
    final rawCourseId = query[courseIdQueryKey]?.trim();

    return HomeWidgetDeeplinkTarget(
      routePath: routePath,
      widgetType: widgetType,
      state: state,
      courseId: rawCourseId?.isEmpty == true ? null : rawCourseId,
    );
  }

  Map<String, dynamic> get trackingParams {
    return {
      'source': sourceValue,
      'widget_type': widgetType.value,
      'state': state.value,
      if (courseId?.isNotEmpty == true) 'course_id': courseId,
    };
  }
}
