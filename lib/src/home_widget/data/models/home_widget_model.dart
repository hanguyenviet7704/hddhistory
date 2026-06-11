part of '../../home_widget.dart';

@JsonSerializable(createToJson: false)
class HomeWidgetCourseModel {
  const HomeWidgetCourseModel({
    this.courseId = '',
    this.title = const {},
    this.description = const {},
    this.image = '',
    this.completedLesson = 0,
    this.totalLesson = 0,
  });

  final String courseId;
  @JsonKey(fromJson: _stringMapFromJson)
  final Map<String, String> title;
  @JsonKey(fromJson: _stringMapFromJson)
  final Map<String, String> description;
  final String image;
  final int completedLesson;
  final int totalLesson;

  factory HomeWidgetCourseModel.fromJson(Map<String, dynamic> json) => _$HomeWidgetCourseModelFromJson(json);

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

@JsonSerializable(createToJson: false)
class HomeWidgetStreakModel {
  const HomeWidgetStreakModel({
    this.weekStartDate,
    this.weekStudy = const [],
    this.studyTime = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
  });

  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime? weekStartDate;
  @JsonKey(fromJson: _boolListFromJson)
  final List<bool> weekStudy;
  final int studyTime;
  final int currentStreak;
  final int bestStreak;

  factory HomeWidgetStreakModel.fromJson(Map<String, dynamic> json) => _$HomeWidgetStreakModelFromJson(json);

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

Map<String, String> _stringMapFromJson(Object? json) {
  if (json is! Map) return const {};
  return json.map((key, value) => MapEntry(key.toString(), value?.toString() ?? ''));
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
