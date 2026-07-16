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

/// True when Home's "recommended" strip should (re)fetch: no suggested
/// courses loaded — either the suggest call failed inside initializeData
/// while skillsets succeeded (so [shouldSelfHealHomeData] never re-fires it)
/// or it never ran. The section hides itself when empty, so without this a
/// suggest-only failure stays invisible until pull-to-refresh. A genuinely
/// empty suggestion list refetches on each Home entry — same accepted
/// trade-off as [shouldSelfHealHomeData]. In-flight dedupe lives in
/// [HomeCubit.ensureSuggestedCoursesLoaded] (loadSuggestCourses doesn't
/// drive [HomeState.status]).
bool shouldEnsureSuggestedCoursesReload(HomeState state) => state.suggestedCourses.isEmpty;

extension HomeStateExtension on HomeState {
  /// Ordered to match the sequence the user tapped Path categories (Feel/
  /// Think/Work/Connect/Learn/Explore Better) during onboarding — see
  /// [UserCubit.setOnboardingPathOrder] — instead of the backend's default
  /// sort. Skillsets outside that selection (or before it's set) keep their
  /// original relative order, appended after the ranked ones.
  List<SkillsetEntity> get skillsets => _orderSkillsetsByOnboardingPaths(
        pageData.items,
        AppDI.injector.get<UserCubit>().state.onboardingPathOrder,
      );
  SkillsetEntity get currentSkillset {
    if (selectedSkillsetIndex == -1) return SkillsetEntity();
    return skillsets.elementAtOrDefault(selectedSkillsetIndex, defaultValue: SkillsetEntity());
  }
  CourseEntity get currentCourse => currentSkillset.courses.elementAtOrDefault(selectedCourseIndex, defaultValue: CourseEntity());
  String get courseName => currentCourse.title.text.isNotEmpty ? currentCourse.title.text : 'Course Roadmap';
  bool isSelectedCourse(String id) => currentCourse.id == id;
}

/// [OnboardingPath] (onboarding's Path-selection categories) and
/// [SkillsetOnboardingIntroduce] (a skillset's onboarding tag) are the same
/// six categories under two different enums — one per side of onboarding vs.
/// content. This is the correspondence between them.
SkillsetOnboardingIntroduce _skillsetIntroduceForPath(OnboardingPath path) => switch (path) {
  OnboardingPath.feelBetter => SkillsetOnboardingIntroduce.myFeelingsFeelLoud,
  OnboardingPath.thinkBetter => SkillsetOnboardingIntroduce.myThoughtsCircle,
  OnboardingPath.workBetter => SkillsetOnboardingIntroduce.imBusyAllDay,
  OnboardingPath.connectBetter => SkillsetOnboardingIntroduce.iTalkToMany,
  OnboardingPath.learnBetter => SkillsetOnboardingIntroduce.whatILearnFades,
  OnboardingPath.exploreBetter => SkillsetOnboardingIntroduce.nothingFeelsNew,
};

List<SkillsetEntity> _orderSkillsetsByOnboardingPaths(List<SkillsetEntity> skillsets, List<OnboardingPath> pathOrder) {
  if (pathOrder.isEmpty || skillsets.isEmpty) return skillsets;
  final introduceOrder = pathOrder.map(_skillsetIntroduceForPath).toList();
  final buckets = List<List<SkillsetEntity>>.generate(introduceOrder.length, (_) => []);
  final unranked = <SkillsetEntity>[];
  for (final skillset in skillsets) {
    final introduce = skillset.onboardingIntroduce;
    final rank = introduce == null ? -1 : introduceOrder.indexOf(introduce);
    if (rank >= 0) {
      buckets[rank].add(skillset);
    } else {
      unranked.add(skillset);
    }
  }
  return [...buckets.expand((bucket) => bucket), ...unranked];
}
