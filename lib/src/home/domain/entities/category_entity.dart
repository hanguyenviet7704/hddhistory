part of '../../home.dart';

@freezed
abstract class CategoryEntity with _$CategoryEntity {
  const factory CategoryEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseEntity> courses,
    CategoryOnboardingIntroduce? onboardingIntroduce,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _CategoryEntity;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) => _$CategoryEntityFromJson(json);
}

enum CategoryOnboardingIntroduce {
  myFeelingsFeelLoud('MY_FEELINGS_FEEL_LOUD'),
  myThoughtsCircle('MY_THOUGHTS_CIRCLE'),
  imBusyAllDay('IM_BUSY_ALL_DAY'),
  iTalkToMany('I_TALK_TO_MANY'),
  whatILearnFades('WHAT_I_LEARN_FADES'),
  nothingFeelsNew('NOTHING_FEELS_NEW'),
  ;

  const CategoryOnboardingIntroduce(this.name);

  final String name;

  String get title => switch (this) {
    myFeelingsFeelLoud => l10n.onboarding.onboardingIntroduceMyFeelings,
    myThoughtsCircle => l10n.onboarding.onboardingIntroduceMyThoughts,
    imBusyAllDay => l10n.onboarding.onboardingIntroduceBusyAllDay,
    iTalkToMany => l10n.onboarding.onboardingIntroduceTalkToMany,
    whatILearnFades => l10n.onboarding.onboardingIntroduceLearnFades,
    nothingFeelsNew => l10n.onboarding.onboardingIntroduceNothingNew,
  };

  String get shortTitle => switch (this) {
    myFeelingsFeelLoud => 'Feel',
    myThoughtsCircle => 'Think',
    imBusyAllDay => 'Work',
    iTalkToMany => 'Connect',
    whatILearnFades => 'Learn',
    nothingFeelsNew => 'Explore',
  };
  
  String get image => switch (this) {
    myFeelingsFeelLoud => AppAsset.icons.app.icHeart.path,
    myThoughtsCircle => AppAsset.icons.app.icCompass.path,
    imBusyAllDay => AppAsset.icons.app.icDirectHit.path,
    iTalkToMany => AppAsset.icons.app.icSpeechBallon.path,
    whatILearnFades => AppAsset.icons.app.icBook.path,
    nothingFeelsNew => AppAsset.icons.app.icWorldMap.path,
  };

  String get imageDisable => switch (this) {
    myFeelingsFeelLoud => AppAsset.icons.app.icHeartDisable.path,
    myThoughtsCircle => AppAsset.icons.app.icCompassDisable.path,
    imBusyAllDay => AppAsset.icons.app.icDirectHitDisable.path,
    iTalkToMany => AppAsset.icons.app.icSpeechBallonDisable.path,
    whatILearnFades => AppAsset.icons.app.icBookDisable.path,
    nothingFeelsNew => AppAsset.icons.app.icWorldMapDisable.path,
  };
}

extension CategoryEntityExtension on CategoryEntity {
  List<CourseEntity> get coursesWithCategory => courses.map((course) => course.copyWith(category: copyWith(courses: []))).toList();

  String get trackingName => title.en;
}

extension CategoryListExtension on List<CategoryEntity> {
  CategoryEntity? categoryFromIndex(int index) => elementAtOrNull(index);

  CategoryEntity resolveCategoryByCourseId(String courseId, {CategoryEntity? fallback}) {
    if (courseId.isEmpty) return fallback ?? const CategoryEntity();
    return firstWhere(
      (category) => category.courses.any((course) => course.id == courseId),
      orElse: () => fallback ?? const CategoryEntity(),
    );
  }

  CourseEntity resolveCourseByCourseId(
    String courseId, {
    CourseEntity? fallback,
    CategoryEntity? categoryFallback,
  }) {
    if (courseId.isEmpty) return fallback ?? const CourseEntity();
    final category = resolveCategoryByCourseId(courseId, fallback: categoryFallback);
    return category.courses.firstWhere(
      (course) => course.id == courseId,
      orElse: () => fallback ?? const CourseEntity(),
    );
  }
}
