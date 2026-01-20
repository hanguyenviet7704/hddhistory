part of '../../home.dart';

enum HomeStatus { initial, loading, success, failure }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeStatus.initial) HomeStatus status,
    @Default(BasePageBreak<SkillsetEntity>()) BasePageBreak<SkillsetEntity> pageData,
    @Default(0) int selectedSkillsetIndex,
    @Default(0) int selectedCourseIndex,
    String? errorMessage,
  }) = _HomeState;

  factory HomeState.initial() => HomeState();

  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}

extension HomeStateExtension on HomeState {
  List<SkillsetEntity> get skillsets => pageData.items;
  SkillsetEntity get currentSkillset {
    if (selectedSkillsetIndex == -1) return SkillsetEntity();
    return skillsets.elementAtOrDefault(selectedSkillsetIndex, defaultValue: SkillsetEntity());
  }
  CourseEntity get currentCourse => currentSkillset.courses.elementAtOrDefault(selectedCourseIndex, defaultValue: CourseEntity());
  String get courseName => currentCourse.title.text.isNotEmpty ? currentCourse.title.text : 'Course Roadmap';
  bool isSelectedCourse(String id) => currentCourse.id == id;
}
