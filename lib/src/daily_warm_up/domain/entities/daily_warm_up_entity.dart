part of '../../daily_warm_up.dart';

@freezed
abstract class DailyWarmUpEntity with _$DailyWarmUpEntity {
  const factory DailyWarmUpEntity({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DailyWarmUpEntity;

  factory DailyWarmUpEntity.fromJson(Map<String, dynamic> json) => _$DailyWarmUpEntityFromJson(json);
}

