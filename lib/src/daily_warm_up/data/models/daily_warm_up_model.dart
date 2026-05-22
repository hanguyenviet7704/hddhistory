part of '../../daily_warm_up.dart';

@freezed
abstract class DailyWarmUpModel with _$DailyWarmUpModel {
  const factory DailyWarmUpModel({
    @Default('') String id,
    @Default('') String name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _DailyWarmUpModel;


  factory DailyWarmUpModel.fromJson(Map<String, dynamic> json) => _$DailyWarmUpModelFromJson(json);
}

extension DailyWarmUpModelExtension on DailyWarmUpModel {
  DailyWarmUpEntity toEntity() => DailyWarmUpEntity(
        id: id,
        name: name,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

