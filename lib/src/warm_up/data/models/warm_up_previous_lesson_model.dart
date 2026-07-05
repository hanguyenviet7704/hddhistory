part of '../../warm_up.dart';

@freezed
abstract class WarmUpPreviousLessonModel with _$WarmUpPreviousLessonModel {
  const factory WarmUpPreviousLessonModel({
    @Default('') String id,
    @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    // Server reuses the daily-warm-up exercise shape for questions.
    @Default([]) List<QuestionModel> questions,
  }) = _WarmUpPreviousLessonModel;

  factory WarmUpPreviousLessonModel.fromJson(Map<String, dynamic> json) => _$WarmUpPreviousLessonModelFromJson(json);
}

extension WarmUpPreviousLessonModelExtension on WarmUpPreviousLessonModel {
  WarmUpPreviousLessonEntity toEntity() => WarmUpPreviousLessonEntity(
    id: id,
    title: title,
    questions: questions.map((q) => q.toEntity()).toList(),
  );
}
