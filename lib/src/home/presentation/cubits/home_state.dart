part of '../../home.dart';

enum HomeStatus { initial, loading, success, failure }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeStatus.initial) HomeStatus status,
    @Default(BasePageBreak<SkillsetEntity>()) BasePageBreak<SkillsetEntity> pageData,
    @Default(BasePageBreak<UserProgressEntity>()) BasePageBreak<UserProgressEntity> coursesPageData,
    @Default(0) int selectedSkillsetIndex,
    @Default(0) int selectedCourseIndex,
    String? errorMessage,
  }) = _HomeState;

  factory HomeState.initial() => HomeState();

  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}

extension HomeStateExtension on HomeState {
  SkillsetEntity get currentSkillset => pageData.items.elementAtOrDefault(selectedSkillsetIndex, defaultValue: SkillsetEntity());
  UserProgressEntity get currentCourse => coursesPageData.items.elementAtOrDefault(selectedCourseIndex, defaultValue: UserProgressEntity());
  
}
