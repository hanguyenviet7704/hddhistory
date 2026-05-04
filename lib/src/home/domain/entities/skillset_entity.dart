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
  final String Function() _imageGetter;

  String get title => _titleGetter(l10n);
  String get image => _imageGetter();
  
  String get name {
    return switch (this) {
      myFeelingsFeelLoud => 'MY_FEELINGS_FEEL_LOUD',
      myThoughtsCircle => 'MY_THOUGHTS_CIRCLE',
      imBusyAllDay => 'IM_BUSY_ALL_DAY',
      iTalkToMany => 'I_TALK_TO_MANY',
      whatILearnFades => 'WHAT_I_LEARN_FADES',
      nothingFeelsNew => 'NOTHING_FEELS_NEW',
    };
  }
  

  static String _myFeelings(Translations t) => t.onboarding.onboardingIntroduceMyFeelings;
  static String _myThoughts(Translations t) => t.onboarding.onboardingIntroduceMyThoughts;
  static String _busyAllDay(Translations t) => t.onboarding.onboardingIntroduceBusyAllDay;
  static String _talkToMany(Translations t) => t.onboarding.onboardingIntroduceTalkToMany;
  static String _learnFades(Translations t) => t.onboarding.onboardingIntroduceLearnFades;
  static String _nothingNew(Translations t) => t.onboarding.onboardingIntroduceNothingNew;

  static String _heart() => AppAsset.icons.app.icHeart.path;
  static String _compass() => AppAsset.icons.app.icCompass.path;
  static String _directHit() => AppAsset.icons.app.icDirectHit.path;
  static String _speechBallon() => AppAsset.icons.app.icSpeechBallon.path;
  static String _book() => AppAsset.icons.app.icBook.path;
  static String _worldMap() => AppAsset.icons.app.icWorldMap.path;
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
