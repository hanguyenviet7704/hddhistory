part of '../../week_recap.dart';

@LazySingleton(as: IWeekRecapRepository)
class WeekRecapRepository implements IWeekRecapRepository {
  final WeekRecapApi _api;

  WeekRecapRepository(this._api);

  @override
  TaskEither<AppException, CurrentWeekRecapEntity> getCurrent({required int tzOffset}) {
    return TaskEither.tryCatch(
      () async {
        // `weekRecapWeekOffset` is 1 — the finished week — in every build that
        // is not a debug review session. See week_recap_debug_seed.dart.
        final response = await _api.getCurrent(tzOffset, weekRecapWeekOffset);

        return (response.data ?? const CurrentWeekRecapModel()).toEntity();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, BasePageBreak<WeekRecapSummaryEntity>> getArchive({
    required int page,
    required int take,
  }) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getArchive(page, take);
        final data = response.data ?? const BasePageBreak<WeekRecapSummaryModel>();

        return BasePageBreak<WeekRecapSummaryEntity>(
          totalPages: data.totalPages,
          currentPage: data.currentPage,
          itemsPerPage: data.itemsPerPage,
          items: data.items.map((item) => item.toEntity()).toList(),
        );
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, WeekRecapEntity> getById(String id) {
    return TaskEither.tryCatch(
      () async {
        final response = await _api.getById(id);
        final model = response.data;
        if (model == null) throw Exception('Week recap $id is empty');

        return model.toEntity();
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }

  @override
  TaskEither<AppException, Unit> markInteracted({
    required String id,
    required bool viewed,
  }) {
    return TaskEither.tryCatch(
      () async {
        if (viewed) {
          await _api.markViewed(id);
        } else {
          await _api.markDismissed(id);
        }

        return unit;
      },
      (error, stackTrace) => AppException.unexpected(error.toString()),
    );
  }
}
