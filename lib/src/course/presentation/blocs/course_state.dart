part of '../../course.dart';

enum CourseStatus { initial, loading, success, failure }

@freezed
abstract class CourseState with _$CourseState {
  const factory CourseState({
    @Default(CourseStatus.initial) CourseStatus status,
    @Default(BasePageBreak<CourseEntity>()) BasePageBreak<CourseEntity> pageData,
    CourseEntity? selectedItem,
    RoadmapEntity? roadmap,
    String? errorMessage,
  }) = _CourseState;

  factory CourseState.initial() => CourseState();

  factory CourseState.fromJson(Map<String, dynamic> json) => _$CourseStateFromJson(json);
}
