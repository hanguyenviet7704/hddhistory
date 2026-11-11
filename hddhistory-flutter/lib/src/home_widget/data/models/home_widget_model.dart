part of '../../home_widget.dart';

@freezed
abstract class HomeWidgetCourseModel with _$HomeWidgetCourseModel {
  const factory HomeWidgetCourseModel({
    @Default('') String courseId,
    @JsonKey(fromJson: _multiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage title,
    @JsonKey(fromJson: _multiLanguageFromJson) @Default(BaseMultiLanguage()) BaseMultiLanguage description,
    @Default('') String image,
    @Default(0) int completedLesson,
    @Default(0) int totalLesson,
  }) = _HomeWidgetCourseModel;

  factory HomeWidgetCourseModel.fromJson(Map<String, dynamic> json) => _$HomeWidgetCourseModelFromJson(json);
}

extension HomeWidgetCourseModelX on HomeWidgetCourseModel {
  HomeWidgetCourseEntity toEntity() {
    return HomeWidgetCourseEntity(
      courseId: courseId,
      title: title,
      description: description,
      image: image,
      completedLesson: completedLesson,
      totalLesson: totalLesson,
    );
  }
}

@freezed
abstract class HomeWidgetStreakModel with _$HomeWidgetStreakModel {
  const factory HomeWidgetStreakModel({
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) DateTime? weekStartDate,
    @JsonKey(fromJson: _boolListFromJson) @Default([]) List<bool> weekStudy,
    @Default(0) int studyTime,
    @Default(0) int currentStreak,
    @Default(0) int bestStreak,
  }) = _HomeWidgetStreakModel;

  factory HomeWidgetStreakModel.fromJson(Map<String, dynamic> json) => _$HomeWidgetStreakModelFromJson(json);
}

extension HomeWidgetStreakModelX on HomeWidgetStreakModel {
  HomeWidgetStreakEntity toEntity() {
    return HomeWidgetStreakEntity(
      weekStartDate: weekStartDate,
      weekStudy: weekStudy,
      studyTime: studyTime,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
    );
  }
}

BaseMultiLanguage _multiLanguageFromJson(Object? json) {
  if (json is! Map) return const BaseMultiLanguage();
  return BaseMultiLanguage.fromJson(Map<String, dynamic>.from(json));
}

List<bool> _boolListFromJson(Object? json) {
  if (json is! List) return const [];
  return json.map((value) => value == true).toList();
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();
