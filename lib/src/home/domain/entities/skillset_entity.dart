part of '../../home.dart';

@freezed
abstract class SkillsetEntity with _$SkillsetEntity {
  const factory SkillsetEntity({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default([]) List<CourseEntity> courses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _SkillsetEntity;

  factory SkillsetEntity.fromJson(Map<String, dynamic> json) => _$SkillsetEntityFromJson(json);
}

enum SkillsetOnboardingIntroduce {
  myFeelingsFeelLoud(
    BaseMultiLanguage(
      en: 'My feelings feel loud — I can\'t read them',
      vi: 'Cảm xúc của tôi rất ồn ào — tôi không thể đọc được chúng',
      zh: '我的感受很嘈杂 — 我无法读懂它们',
    ),
    'assets/icons/app/ic_heart.png',
  ),
  myThoughtsCircle(
    BaseMultiLanguage(
      en: 'My thoughts circle but never land',
      vi: 'Suy nghĩ của tôi cứ xoay vòng mà không đi đến đâu',
      zh: '我的思绪不停打转，却从未落定',
    ),
    'assets/icons/app/ic_compass.png',
  ),
  imBusyAllDay(
    BaseMultiLanguage(
      en: 'I\'m busy all day, yet feel I did nothing',
      vi: 'Tôi bận rộn cả ngày, nhưng lại cảm thấy chẳng làm được gì',
      zh: '我忙碌了一整天，却感觉什么都没做',
    ),
    'assets/icons/app/ic_direct_hit.png',
  ),
  iTalkToMany(
    BaseMultiLanguage(
      en: 'I talk to many, connect with few',
      vi: 'Tôi nói chuyện với nhiều người, nhưng kết nối được với rất ít',
      zh: '我与很多人交谈，却与少数人产生共鸣',
    ),
    'assets/icons/app/ic_speech_ballon.png',
  ),
  whatILearnFades(
    BaseMultiLanguage(
      en: 'What I learn fades by next week',
      vi: 'Những gì tôi học được sẽ phai mờ vào tuần sau',
      zh: '我学到的东西到下周就忘了',
    ),
    'assets/icons/app/ic_book.png',
  ),
  nothingFeelsNew(
    BaseMultiLanguage(
      en: 'Nothing feels new — I miss that spark',
      vi: 'Không có gì mới mẻ — tôi nhớ cảm giác hứng khởi đó',
      zh: '没有什么让我感到新鲜 — 我怀念那种火花',
    ),
    'assets/icons/app/ic_world_map.png',
  );

  const SkillsetOnboardingIntroduce(this.title, this.image);

  final BaseMultiLanguage title;
  final String image;
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
