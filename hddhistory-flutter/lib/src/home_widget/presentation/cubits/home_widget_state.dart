part of '../../home_widget.dart';

enum HomeWidgetStatus { initial, loading, success, failure }

class HomeWidgetState {
  const HomeWidgetState({
    this.status = HomeWidgetStatus.initial,
    this.results = const [],
    this.errorMessage,
  });

  final HomeWidgetStatus status;
  final List<HomeWidgetSyncResult> results;
  final String? errorMessage;

  factory HomeWidgetState.initial() => const HomeWidgetState();

  HomeWidgetState copyWith({
    HomeWidgetStatus? status,
    List<HomeWidgetSyncResult>? results,
    String? errorMessage,
  }) {
    return HomeWidgetState(
      status: status ?? this.status,
      results: results ?? this.results,
      errorMessage: errorMessage,
    );
  }
}
