part of '../../week_recap.dart';

enum WeekRecapStatus { initial, loading, success, failure }

@freezed
abstract class WeekRecapState with _$WeekRecapState {
  const factory WeekRecapState({
    @Default(WeekRecapStatus.initial) WeekRecapStatus status,

    /// Last week's poster, or null when the week was too quiet to wrap.
    WeekRecapEntity? current,
    @Default(0) int archiveCount,

    /// The Sổ tay grid.
    @Default(WeekRecapStatus.initial) WeekRecapStatus archiveStatus,
    @Default(BasePageBreak<WeekRecapSummaryEntity>()) BasePageBreak<WeekRecapSummaryEntity> archive,

    /// The recap the poster screen is showing. Same object as [current] when
    /// opened from the banner or the popup; a fetched older one when opened
    /// from Sổ tay.
    WeekRecapEntity? opened,
    @Default(WeekRecapStatus.initial) WeekRecapStatus openedStatus,
    String? errorMessage,
  }) = _WeekRecapState;

  factory WeekRecapState.initial() => const WeekRecapState();
}

extension WeekRecapStateX on WeekRecapState {
  /// What the Library banner and its popups read.
  CurrentWeekRecapEntity get bannerSource => CurrentWeekRecapEntity(recap: current, archiveCount: archiveCount);

  /// The banner shows its "MỚI" pill for an unopened recap, or one opened
  /// today.
  bool get isBannerNew => bannerSource.isBannerNew;

  /// The Library row into Sổ tay exists only once there is something in it.
  bool get hasArchive => archiveCount > 0;

  bool get shouldShowMondayPopup => bannerSource.shouldShowPopup;
}
