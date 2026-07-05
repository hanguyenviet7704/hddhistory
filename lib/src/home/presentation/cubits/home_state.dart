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
    @Default(null) QuoteEntity? quote,
    @Default([]) List<SuggestedCourseEntity> suggestedCourses,
  }) = _HomeState;

  factory HomeState.initial() => HomeState();

  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}

/// True when the home dataset should be (re)fetched by a page that needs it:
/// no skillsets loaded and no load currently running. Kept as a pure function
/// so the self-heal trigger is unit-testable.
bool shouldSelfHealHomeData(HomeState state) => state.skillsets.isEmpty && state.status != HomeStatus.loading;

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
