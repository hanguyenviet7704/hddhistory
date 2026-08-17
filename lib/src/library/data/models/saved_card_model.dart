part of '../../library.dart';

@freezed
abstract class SavedCardModel with _$SavedCardModel {
  const factory SavedCardModel({
    @JsonKey(name: '_id') @Default('') String id,
    @Default('') String keypointId,
    @Default('') String lessonId,
    @Default('') String courseId,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default('') String recapText,
    @Default(BaseMultiLanguage()) BaseMultiLanguage courseTitle,
  }) = _SavedCardModel;

  factory SavedCardModel.fromJson(Map<String, dynamic> json) => _$SavedCardModelFromJson(json);
}

extension SavedCardModelX on SavedCardModel {
  SavedCardEntity toEntity() => SavedCardEntity(
    id: id,
    keypointId: keypointId,
    lessonId: lessonId,
    courseId: courseId,
    title: title,
    description: description,
    image: image,
    recapText: recapText,
    courseTitle: courseTitle,
  );
}
