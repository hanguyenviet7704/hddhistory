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
    @Default(BaseMultiLanguage()) BaseMultiLanguage summary,
    @Default('') String image,
    @Default(LessonVideoModel()) LessonVideoModel video,
    @JsonKey(unknownEnumValue: LessonPublishStatus.unknown) @Default(LessonPublishStatus.draft) LessonPublishStatus status,
    @Default([]) List<KeypointModel> keypoints,
    @Default(BaseMultiLanguage()) BaseMultiLanguage estimateCompleTime,
    @Default(0) int estimateCompleTimeNumber,
    @Default('') String aiConfig,
    @Default(TagModel()) TagModel icon,
    @Default(TagModel()) TagModel lightIcon,
    @JsonKey(unknownEnumValue: ProcessEnum.unknown) @Default(ProcessEnum.notStarted) ProcessEnum progess,
    @Default(ConversationAvatarModel()) ConversationAvatarModel animation,
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
  @JsonValue('video')
  video,
  @JsonValue('unknown')
  unknown
  ;

  String get trackingName {
    return switch (this) {
      roleplay => 'roleplay',
      lesson => 'lesson',
      output => 'output',
      video => 'video',
      unknown => 'unknown',
    };
  }

  bool get blocksRoadmap => this != LessonType.output;
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
    summary: summary,
    image: image,
    video: video.toEntity(),
    status: status,
    keypoints: keypoints.map((model) => model.toEntity()).toList(),
    estimateCompleTime: estimateCompleTime,
    estimateCompleTimeNumber: estimateCompleTimeNumber,
    aiConfig: aiConfig,
    icon: icon.toEntity(),
    lightIcon: lightIcon.toEntity(),
    animation: animation.toEntity(),
    index: index,
    progess: progess,
  );
}
