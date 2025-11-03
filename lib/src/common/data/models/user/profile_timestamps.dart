part of '../models.dart';

@freezed
abstract class ProfileTimestamps with _$ProfileTimestamps {
  const factory ProfileTimestamps({
    @Default(null) DateTime? lastLessonCompletedAt,
  }) = _ProfileTimestamps;

  factory ProfileTimestamps.fromJson(Map<String, dynamic> json) => _$ProfileTimestampsFromJson(json);
}
