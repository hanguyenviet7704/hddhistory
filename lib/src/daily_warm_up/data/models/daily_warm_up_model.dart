part of '../../daily_warm_up.dart';

@freezed
abstract class DailyWarmUpModel with _$DailyWarmUpModel {
  const factory DailyWarmUpModel({
    @Default('') String courseId,
    @Default('') String suggestedCourseId,
    @Default('') String lessonId,
    @Default('') String lessonIdkeypointId,
    @Default(false) bool isKeypointCompleted,
    @Default([]) List<QuestionModel> questions,
  }) = _DailyWarmUpModel;


  factory DailyWarmUpModel.fromJson(Map<String, dynamic> json) => _$DailyWarmUpModelFromJson(json);
}

extension DailyWarmUpModelExtension on DailyWarmUpModel {
  DailyWarmUpEntity toEntity() => DailyWarmUpEntity(
        courseId: courseId,
        suggestedCourseId: suggestedCourseId,
        lessonId: lessonId,
        lessonIdkeypointId: lessonIdkeypointId,
        isKeypointCompleted: isKeypointCompleted,
        questions: questions.map((q) => q.toEntity()).toList(),
      );
}

