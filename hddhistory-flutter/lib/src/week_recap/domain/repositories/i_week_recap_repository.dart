part of '../../week_recap.dart';

abstract interface class IWeekRecapRepository {
  /// Last week's poster, plus how many the learner has in total.
  ///
  /// [tzOffset] is minutes east of UTC: the server cuts the week on the
  /// learner's Monday, not its own.
  TaskEither<AppException, CurrentWeekRecapEntity> getCurrent({required int tzOffset});

  TaskEither<AppException, BasePageBreak<WeekRecapSummaryEntity>> getArchive({
    required int page,
    required int take,
  });

  TaskEither<AppException, WeekRecapEntity> getById(String id);

  /// Records that the learner opened their week, or chose "Để sau". Either way
  /// the Monday popup is done for this recap.
  TaskEither<AppException, Unit> markInteracted({
    required String id,
    required bool viewed,
  });
}
