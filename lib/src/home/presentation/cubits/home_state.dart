part of '../../home.dart';

enum HomeStatus { initial, loading, success, failure }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeStatus.initial) HomeStatus status,
    @Default(BasePageBreak<SkillsetEntity>()) BasePageBreak<SkillsetEntity> pageData,
    @Default(BasePageBreak<UserProgressEntity>()) BasePageBreak<UserProgressEntity> coursesPageData,
    SkillsetEntity? selectedItem,
    String? errorMessage,
    @Default(false) bool isLoadingCourses,
    @Default(false) bool isLoadingSkillsets,
  }) = _HomeState;

  factory HomeState.initial() => HomeState();

  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}
