
part of '../../home_widget.dart';

enum HomeWidgetStatus { initial, loading, success, failure }

@freezed
abstract class HomeWidgetState with _$HomeWidgetState {
  const factory HomeWidgetState({
    @Default(HomeWidgetStatus.initial) HomeWidgetStatus status,
    HomeWidgetEntity? selectedItem,
    String? errorMessage,
  }) = _HomeWidgetState;

  factory HomeWidgetState.initial() => HomeWidgetState();

  factory HomeWidgetState.fromJson(Map<String, dynamic> json) => _$HomeWidgetStateFromJson(json);
}

