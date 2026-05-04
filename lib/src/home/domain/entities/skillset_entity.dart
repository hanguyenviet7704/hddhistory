part of '../../home.dart';

@freezed
abstract class SkillsetEntity with _$SkillsetEntity {
  const factory SkillsetEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseEntity> courses,
    SkillsetOnboardingIntroduce? onboardingIntroduce,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetEntity;

  factory SkillsetEntity.fromJson(Map<String, dynamic> json) => _$SkillsetEntityFromJson(json);
}

enum SkillsetOnboardingIntroduce {
  myFeelingsFeelLoud(_myFeelings, _heart),
  myThoughtsCircle(_myThoughts, _compass),
  imBusyAllDay(_busyAllDay, _directHit),
  iTalkToMany(_talkToMany, _speechBallon),
  whatILearnFades(_learnFades, _book),
  nothingFeelsNew(_nothingNew, _worldMap);

  const SkillsetOnboardingIntroduce(this._titleGetter, this._imageGetter);

  final String Function(Translations) _titleGetter;
  final AssetGenImage Function() _imageGetter;

  String get title => _titleGetter(l10n);
  String get name => title;
  AssetGenImage get image => _imageGetter();

  static String _myFeelings(Translations t) => t.onboarding.onboardingIntroduceMyFeelings;
  static String _myThoughts(Translations t) => t.onboarding.onboardingIntroduceMyThoughts;
  static String _busyAllDay(Translations t) => t.onboarding.onboardingIntroduceBusyAllDay;
  static String _talkToMany(Translations t) => t.onboarding.onboardingIntroduceTalkToMany;
  static String _learnFades(Translations t) => t.onboarding.onboardingIntroduceLearnFades;
  static String _nothingNew(Translations t) => t.onboarding.onboardingIntroduceNothingNew;

  static AssetGenImage _heart() => AppAsset.icons.app.icHeart;
  static AssetGenImage _compass() => AppAsset.icons.app.icCompass;
  static AssetGenImage _directHit() => AppAsset.icons.app.icDirectHit;
  static AssetGenImage _speechBallon() => AppAsset.icons.app.icSpeechBallon;
  static AssetGenImage _book() => AppAsset.icons.app.icBook;
  static AssetGenImage _worldMap() => AppAsset.icons.app.icWorldMap;
}

extension SkillsetEntityExtension on SkillsetEntity {
  List<CourseEntity> get coursesWithSkillset => courses.map((course) => course.copyWith(skillset: copyWith(courses: []))).toList();

  String get trackingName => title.en;
}

extension SkillsetListExtension on List<SkillsetEntity> {
  SkillsetEntity? skillsetFromIndex(int index) => elementAtOrNull(index);

  SkillsetEntity resolveSkillsetByCourseId(String courseId, {SkillsetEntity? fallback}) {
    if (courseId.isEmpty) return fallback ?? const SkillsetEntity();
    return firstWhere(
      (skillset) => skillset.courses.any((course) => course.id == courseId),
      orElse: () => fallback ?? const SkillsetEntity(),
    );
  }

  CourseEntity resolveCourseByCourseId(
    String courseId, {
    CourseEntity? fallback,
    SkillsetEntity? skillsetFallback,
  }) {
    if (courseId.isEmpty) return fallback ?? const CourseEntity();
    final skillset = resolveSkillsetByCourseId(courseId, fallback: skillsetFallback);
    return skillset.courses.firstWhere(
      (course) => course.id == courseId,
      orElse: () => fallback ?? const CourseEntity(),
    );
  }
}
