
part of '../../daily_warm_up.dart';

enum DailyWarmUpStatus { initial, loading, success, failure }

@freezed
abstract class DailyWarmUpState with _$DailyWarmUpState {
  const factory DailyWarmUpState({
    @Default(DailyWarmUpStatus.initial) DailyWarmUpStatus status,
    DailyWarmUpEntity? selectedItem,
    String? errorMessage,
  }) = _DailyWarmUpState;

  factory DailyWarmUpState.initial() => DailyWarmUpState();

  factory DailyWarmUpState.fromJson(Map<String, dynamic> json) => _$DailyWarmUpStateFromJson(json);
}

