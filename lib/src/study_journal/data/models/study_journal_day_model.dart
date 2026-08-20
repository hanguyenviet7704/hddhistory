part of '../../study_journal.dart';

/// One COURSE the learner touched that day, with how much of it they did.
@freezed
abstract class StudyJournalCourseModel with _$StudyJournalCourseModel {
  const factory StudyJournalCourseModel({
    @Default('') String courseId,
    @Default('') String title,
    @Default('') String image,
    @Default(0) int lessons,
    @Default(0) int minutes,
  }) = _StudyJournalCourseModel;

  factory StudyJournalCourseModel.fromJson(Map<String, dynamic> json) => _$StudyJournalCourseModelFromJson(json);
}

/// One habit ticked that day (the "THÓI QUEN ĐƯỢC LUYỆN TẬP" list).
@freezed
abstract class StudyJournalHabitModel with _$StudyJournalHabitModel {
  const factory StudyJournalHabitModel({
    @Default('') String userHabitId,
    @Default('') String habitId,
    @Default('') String title,
    @Default('') String image,
    String? method,
    String? note,
  }) = _StudyJournalHabitModel;

  factory StudyJournalHabitModel.fromJson(Map<String, dynamic> json) => _$StudyJournalHabitModelFromJson(json);
}

@freezed
abstract class StudyJournalDaySummaryModel with _$StudyJournalDaySummaryModel {
  const factory StudyJournalDaySummaryModel({
    @Default(0) int lessons,
    @Default(0) int minutes,
    @Default(0) int habits,
  }) = _StudyJournalDaySummaryModel;

  factory StudyJournalDaySummaryModel.fromJson(Map<String, dynamic> json) =>
      _$StudyJournalDaySummaryModelFromJson(json);
}

/// Response of `GET /courses-user-progress/study-journal/day`.
@freezed
abstract class StudyJournalDayDetailModel with _$StudyJournalDayDetailModel {
  const factory StudyJournalDayDetailModel({
    @Default('') String date,
    @Default(StudyJournalDaySummaryModel()) StudyJournalDaySummaryModel summary,
    @Default(<StudyJournalCourseModel>[]) List<StudyJournalCourseModel> courses,
    @Default(<StudyJournalHabitModel>[]) List<StudyJournalHabitModel> habits,
  }) = _StudyJournalDayDetailModel;

  factory StudyJournalDayDetailModel.fromJson(Map<String, dynamic> json) => _$StudyJournalDayDetailModelFromJson(json);
}

extension StudyJournalDayDetailModelX on StudyJournalDayDetailModel {
  StudyJournalDayDetailEntity toEntity() => StudyJournalDayDetailEntity(
    date: _parseDate(date) ?? DateTime.now(),
    lessons: summary.lessons,
    minutes: summary.minutes,
    courses: courses
        .map(
          (item) => StudyJournalCourseEntity(
            courseId: item.courseId,
            title: item.title,
            image: item.image,
            lessons: item.lessons,
            minutes: item.minutes,
          ),
        )
        .toList(),
    habits: habits
        .map(
          (habit) => StudyJournalHabitEntity(
            userHabitId: habit.userHabitId,
            habitId: habit.habitId,
            title: habit.title,
            image: habit.image,
            note: habit.note ?? '',
          ),
        )
        .toList(),
  );
}
