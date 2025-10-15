part of '../../data_collect.dart';

enum DataCollectStatus { initial, loading, success, failure }

@freezed
abstract class DataCollectState with _$DataCollectState {
  const factory DataCollectState({
    @Default(DataCollectStatus.initial) DataCollectStatus status,
    @Default([]) List<UserCollectDataEntity> items,
    UserCollectDataEntity? selectedItem,
    String? errorMessage,
  }) = _DataCollectState;

  factory DataCollectState.initial() => const DataCollectState();

  factory DataCollectState.fromJson(Map<String, dynamic> json) => _$DataCollectStateFromJson(json);
}
