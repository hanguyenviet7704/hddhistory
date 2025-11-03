part of '../models.dart';

@freezed
abstract class ProfileGeolocation with _$ProfileGeolocation {
  const factory ProfileGeolocation({
    @Default('') String profileId,
    @Default('') String currentCountry,
    @Default('') String currentCountryCode,
    @Default('') String currentCity,
    @Default('') String currentRegion,
    @Default('') String currentTimezone,
    @Default(0.0) double currentLatitude,
    @Default(0.0) double currentLongitude,
    @Default('') String geoSource,
    @Default('') String geoLastUpdatedAt,
  }) = _ProfileGeolocation;

  factory ProfileGeolocation.fromJson(Map<String, dynamic> json) => _$ProfileGeolocationFromJson(json);
}
