part of '../../lesson.dart';

@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default('') String learningItemId,
    @Default(LessonType.lesson) LessonType type,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<KeypointModel> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default(TagModel()) TagModel icon,
    @Default(TagModel()) TagModel lightIcon,
    @Default(ProcessEnum.notStarted) ProcessEnum progess,
    @Default(0) int index,
  }) = _LessonModel;

  factory LessonModel.fromJson(Map<String, dynamic> json) => _$LessonModelFromJson(json);
}

enum LessonPublishStatus {
  @JsonValue('published')
  published,
  @JsonValue('draft')
  draft,
  @JsonValue('inactive')
  inactive,
}

enum LessonType {
  @JsonValue('roleplay')
  roleplay,
  @JsonValue('lesson')
  lesson,
  @JsonValue('output')
  output,
}

enum ProcessEnum {
  @JsonValue('done')
  done,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('not_started')
  notStarted;

  int get rank {
    return switch (this) {
      done => 2,
      inProgress => 1,
      notStarted => 0
    };
  }
}

extension LessonModelExtension on LessonModel {
  LessonEntity toEntity() => LessonEntity(
    id: id,
    courseId: courseId,
    learningItemId: learningItemId,
    type: type,
    title: title,
    description: description,
    image: image,
    status: status,
    keypoints: keypoints.map((model) => model.toEntity()).toList(),
    estimateCompleTime: estimateCompleTime,
    icon: icon.toEntity(),
    lightIcon: lightIcon.toEntity(),
    index: index,
    progess: progess,
  );
}
