part of '../../course.dart';

/// Which strip a section is. The server decides both the kind and the order —
/// the app renders the list it is given.
enum ExploreSectionType {
  @JsonValue('curated')
  curated,
  @JsonValue('weeklyTop')
  weeklyTop,
  @JsonValue('becauseYou')
  becauseYou,
  @JsonValue('topicChips')
  topicChips,

  /// A section kind this build does not know about. Rendered as nothing rather
  /// than crashing the tab, so the server can ship a new strip to newer clients
  /// without breaking older ones.
  @JsonValue('unknown')
  unknown,
}

@freezed
abstract class ExploreSectionModel with _$ExploreSectionModel {
  const factory ExploreSectionModel({
    @JsonKey(unknownEnumValue: ExploreSectionType.unknown)
    @Default(ExploreSectionType.unknown)
    ExploreSectionType type,
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default([]) List<CourseModel> courses,

    /// `becauseYou` only: the finished course the suggestions hang off.
    CourseModel? sourceCourse,
  }) = _ExploreSectionModel;

  factory ExploreSectionModel.fromJson(Map<String, dynamic> json) => _$ExploreSectionModelFromJson(json);
}

@freezed
abstract class ExploreResponseModel with _$ExploreResponseModel {
  const factory ExploreResponseModel({
    @Default([]) List<ExploreSectionModel> sections,
  }) = _ExploreResponseModel;

  factory ExploreResponseModel.fromJson(Map<String, dynamic> json) => _$ExploreResponseModelFromJson(json);
}

extension ExploreSectionModelExtension on ExploreSectionModel {
  ExploreSectionEntity toEntity() => ExploreSectionEntity(
    type: type,
    id: id,
    title: title,
    description: description,
    courses: courses.map((c) => c.toEntity()).toList(),
    sourceCourse: sourceCourse?.toEntity(),
  );
}
