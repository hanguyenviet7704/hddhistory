part of '../../home.dart';

enum HomeStatus { initial, loading, success, failure }

@freezed
abstract class HomeState with _$HomeState {
  const factory HomeState({
    @Default(HomeStatus.initial) HomeStatus status,
    @Default(BasePageBreak<CategoryEntity>()) BasePageBreak<CategoryEntity> pageData,
    @Default(0) int selectedCategoryIndex,
    @Default(0) int selectedCourseIndex,
    String? errorMessage,
    @Default(null) QuoteEntity? quote,
    @Default([]) List<SuggestedCourseEntity> suggestedCourses,
    // Admin-configurable promo banner between "New today" and "Jump back in".
    // Null until the first fetch resolves; a fetch failure leaves it null
    // (see [HomeCubit.loadHomeBanner]) rather than surfacing an error, so the
    // section just stays collapsed instead of blocking the rest of Home.
    @Default(null) HomeBannerEntity? homeBanner,
    // Optional-update header banner on Home. Session-only (default false;
    // set by [HomeCubit.checkOptionalUpdate], cleared by dismiss/update).
    @Default(false) bool showUpdateBanner,
  }) = _HomeState;

  factory HomeState.initial() => HomeState();

  factory HomeState.fromJson(Map<String, dynamic> json) => _$HomeStateFromJson(json);
}

/// True when the home dataset should be (re)fetched by a page that needs it:
/// no categories loaded and no load currently running. Kept as a pure function
/// so the self-heal trigger is unit-testable.
bool shouldSelfHealHomeData(HomeState state) => state.categories.isEmpty && state.status != HomeStatus.loading;

/// True when Home's "recommended" strip should (re)fetch: no suggested
/// courses loaded — either the suggest call failed inside initializeData
/// while categories succeeded (so [shouldSelfHealHomeData] never re-fires it)
/// or it never ran. The section hides itself when empty, so without this a
/// suggest-only failure stays invisible until pull-to-refresh. A genuinely
/// empty suggestion list refetches on each Home entry — same accepted
/// trade-off as [shouldSelfHealHomeData]. In-flight dedupe lives in
/// [HomeCubit.ensureSuggestedCoursesLoaded] (loadSuggestCourses doesn't
/// drive [HomeState.status]).
bool shouldEnsureSuggestedCoursesReload(HomeState state) => state.suggestedCourses.isEmpty;

extension HomeStateExtension on HomeState {
  /// Thứ tự chủ đề theo nhánh user chọn ở onboarding (branch.categoryId,
  /// theo thứ tự chọn) — xem [UserCubit.setOnboardingCategoryOrder]. Chủ đề
  /// ngoài danh sách (hoặc chưa set) giữ thứ tự backend, xếp sau.
  List<CategoryEntity> get categories => _orderCategoriesByIds(pageData.items, AppDI.injector.get<UserCubit>().state.onboardingCategoryOrder);
  CategoryEntity get currentCategory {
    if (selectedCategoryIndex == -1) return CategoryEntity();
    return categories.elementAtOrDefault(selectedCategoryIndex, defaultValue: CategoryEntity());
  }
  CourseEntity get currentCourse => currentCategory.courses.elementAtOrDefault(selectedCourseIndex, defaultValue: CourseEntity());
  String get courseName => currentCourse.title.text.isNotEmpty ? currentCourse.title.text : 'Course Roadmap';
  bool isSelectedCourse(String id) => currentCourse.id == id;
}

List<CategoryEntity> _orderCategoriesByIds(List<CategoryEntity> categories, List<String> idOrder) {
  if (idOrder.isEmpty || categories.isEmpty) return categories;
  final buckets = List<List<CategoryEntity>>.generate(idOrder.length, (_) => []);
  final unranked = <CategoryEntity>[];
  for (final category in categories) {
    final rank = idOrder.indexOf(category.id);
    if (rank >= 0) {
      buckets[rank].add(category);
    } else {
      unranked.add(category);
    }
  }
  return [...buckets.expand((bucket) => bucket), ...unranked];
}
