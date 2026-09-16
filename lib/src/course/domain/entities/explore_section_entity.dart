part of '../../course.dart';

@freezed
abstract class ExploreSectionEntity with _$ExploreSectionEntity {
  const factory ExploreSectionEntity({
    @Default(ExploreSectionType.unknown) ExploreSectionType type,
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default([]) List<CourseEntity> courses,
    CourseEntity? sourceCourse,
  }) = _ExploreSectionEntity;

  factory ExploreSectionEntity.fromJson(Map<String, dynamic> json) => _$ExploreSectionEntityFromJson(json);
}

extension ExploreSectionEntityExtension on ExploreSectionEntity {
  /// A strip with nothing in it is a heading over blank space. The server drops
  /// empty curated rows already; this guards the computed ones and any future
  /// section kind.
  bool get hasContent => type == ExploreSectionType.topicChips || courses.isNotEmpty;
}
