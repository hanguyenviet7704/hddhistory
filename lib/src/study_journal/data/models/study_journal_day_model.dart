part of '../../study_journal.dart';

/// One keypoint the learner finished on the tapped day (the "BÀI HỌC" list).
@freezed
abstract class StudyJournalItemModel with _$StudyJournalItemModel {
  const factory StudyJournalItemModel({
    @Default('') String courseId,
    @Default('') String courseTitle,
    @Default('') String image,
    @Default('') String lessonId,
    @Default('') String lessonTitle,
    @Default('') String keypointId,
    @Default('') String title,
    @Default(0) int minutes,
    @Default(false) bool passed,
    DateTime? submittedAt,
  }) = _StudyJournalItemModel;

  factory StudyJournalItemModel.fromJson(Map<String, dynamic> json) => _$StudyJournalItemModelFromJson(json);
}

/// One habit ticked that day (the "THÓI QUEN ĐƯỢC LUYỆN TẬP" list).
@freezed
abstract class StudyJournalHabitModel with _$StudyJournalHabitModel {
  const factory StudyJournalHabitModel({
    @Default('') String userHabitId,
    @Default('') String habitId,
    @Default('') String title,
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
    @Default(<StudyJournalItemModel>[]) List<StudyJournalItemModel> lessons,
    @Default(<StudyJournalHabitModel>[]) List<StudyJournalHabitModel> habits,
  }) = _StudyJournalDayDetailModel;

  factory StudyJournalDayDetailModel.fromJson(Map<String, dynamic> json) => _$StudyJournalDayDetailModelFromJson(json);
}

extension StudyJournalDayDetailModelX on StudyJournalDayDetailModel {
  StudyJournalDayDetailEntity toEntity() => StudyJournalDayDetailEntity(
    date: _parseDate(date) ?? DateTime.now(),
    minutes: summary.minutes,
    lessons: lessons
        .map(
          (item) => StudyJournalItemEntity(
            courseId: item.courseId,
            courseTitle: item.courseTitle,
            image: item.image,
            lessonId: item.lessonId,
            lessonTitle: item.lessonTitle,
            keypointId: item.keypointId,
            title: item.title,
            minutes: item.minutes,
            passed: item.passed,
            // Server sends UTC; the sheet prints a clock time, so it has to be
            // the learner's own clock or the row reads as the wrong hour.
            submittedAt: item.submittedAt?.toLocal(),
          ),
        )
        .toList(),
    habits: habits
        .map(
          (habit) => StudyJournalHabitEntity(
            userHabitId: habit.userHabitId,
            habitId: habit.habitId,
            title: habit.title,
            note: habit.note ?? '',
          ),
        )
        .toList(),
  );
}
