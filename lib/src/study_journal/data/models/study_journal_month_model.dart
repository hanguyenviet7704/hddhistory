part of '../../study_journal.dart';

/// One day the server reports study on. Days with nothing on them are NOT sent
/// — the calendar already knows the shape of the month and fills the gaps.
@freezed
abstract class StudyJournalDayModel with _$StudyJournalDayModel {
  const factory StudyJournalDayModel({
    @Default('') String date,
    @Default(0) int keypoints,
    @Default(0) int level,
  }) = _StudyJournalDayModel;

  factory StudyJournalDayModel.fromJson(Map<String, dynamic> json) => _$StudyJournalDayModelFromJson(json);
}

@freezed
abstract class StudyJournalSummaryModel with _$StudyJournalSummaryModel {
  const factory StudyJournalSummaryModel({
    @Default(0) int activeDays,
    @Default(0) int keypoints,
  }) = _StudyJournalSummaryModel;

  factory StudyJournalSummaryModel.fromJson(Map<String, dynamic> json) => _$StudyJournalSummaryModelFromJson(json);
}

/// Response of `GET /courses-user-progress/study-journal`.
@freezed
abstract class StudyJournalMonthModel with _$StudyJournalMonthModel {
  const factory StudyJournalMonthModel({
    @Default('') String month,
    @Default(<StudyJournalDayModel>[]) List<StudyJournalDayModel> days,
    @Default(StudyJournalSummaryModel()) StudyJournalSummaryModel summary,
    String? firstActiveDate,
  }) = _StudyJournalMonthModel;

  factory StudyJournalMonthModel.fromJson(Map<String, dynamic> json) => _$StudyJournalMonthModelFromJson(json);
}

extension StudyJournalMonthModelX on StudyJournalMonthModel {
  StudyJournalMonthEntity toEntity() {
    // Keyed by date rather than kept as a list: the calendar asks "what about
    // the 14th?" once per cell, and a linear scan per cell is a lookup the
    // widget should not be paying for while the user swipes months.
    final byDate = <String, StudyJournalDayEntity>{};
    for (final day in days) {
      final parsed = _parseDate(day.date);
      if (parsed == null) continue;
      byDate[day.date] = StudyJournalDayEntity(
        date: parsed,
        keypoints: day.keypoints < 0 ? 0 : day.keypoints,
        level: day.level.clamp(0, 4),
      );
    }

    return StudyJournalMonthEntity(
      month: _parseMonth(month) ?? DateTime.now(),
      days: byDate,
      activeDays: summary.activeDays,
      keypoints: summary.keypoints,
      firstActiveDate: _parseDate(firstActiveDate ?? ''),
    );
  }
}

/// `YYYY-MM-DD` → local DateTime at midnight, or null for anything else.
///
/// Parsed by hand instead of `DateTime.parse`: that would accept a full
/// timestamp and hand back a UTC instant, and a day cell compared against a
/// UTC midnight lights up the wrong square for every user east of Greenwich.
DateTime? _parseDate(String value) {
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;

  return DateTime(year, month, day);
}

DateTime? _parseMonth(String value) {
  final parts = value.split('-');
  if (parts.length != 2) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  if (year == null || month == null) return null;

  return DateTime(year, month);
}
