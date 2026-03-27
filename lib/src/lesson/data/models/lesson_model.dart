part of '../../lesson.dart';

@freezed
abstract class LessonModel with _$LessonModel {
  const factory LessonModel({
    @Default('') @JsonKey(name: '_id') String id,
    @Default('') String courseId,
    @Default('') String learningItemId,
    @JsonKey(unknownEnumValue: LessonType.unknown) @Default(LessonType.lesson) LessonType type,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @JsonKey(unknownEnumValue: LessonPublishStatus.unknown) @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<KeypointModel> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default(TagModel()) TagModel icon,
    @Default(TagModel()) TagModel lightIcon,
    @JsonKey(unknownEnumValue: ProcessEnum.unknown) @Default(ProcessEnum.notStarted) ProcessEnum progess,
    @Default('') String animation,
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
  @JsonValue('unknown')
  unknown,
}

enum LessonType {
  @JsonValue('roleplay')
  roleplay,
  @JsonValue('lesson')
  lesson,
  @JsonValue('output')
  output,
  @JsonValue('unknown')
  unknown
  ;

  String get trackingName {
    return switch (this) {
      roleplay => 'roleplay',
      lesson => 'lesson',
      output => 'output',
      unknown => 'unknown',
    };
  }
}

enum ProcessEnum {
  @JsonValue('done')
  done,
  @JsonValue('in_progress')
  inProgress,
  @JsonValue('not_started')
  notStarted,
  @JsonValue('unknown')
  unknown
  ;

  int get rank {
    return switch (this) {
      done => 2,
      inProgress => 1,
      notStarted => 0,
      unknown => -1,
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
    animation: animation,
    index: index,
    progess: progess,
  );
}
