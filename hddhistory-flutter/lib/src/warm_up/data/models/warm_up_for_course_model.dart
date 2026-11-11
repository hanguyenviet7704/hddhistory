part of '../../warm_up.dart';

@freezed
abstract class WarmUpForCourseModel with _$WarmUpForCourseModel {
  const factory WarmUpForCourseModel({
    @Default(false) bool isDue,
    WarmUpPreviousLessonModel? previousLesson,
  }) = _WarmUpForCourseModel;

  factory WarmUpForCourseModel.fromJson(Map<String, dynamic> json) => _$WarmUpForCourseModelFromJson(json);
}

extension WarmUpForCourseModelExtension on WarmUpForCourseModel {
  WarmUpForCourseEntity toEntity() => WarmUpForCourseEntity(
    isDue: isDue,
    previousLesson: previousLesson?.toEntity(),
  );
}
