part of '../../../common.dart';

@lazySingleton
class ConnectivityCubit extends Cubit<ConnectivityState> {
  final ConnectivityService _connectivityService;

  ConnectivityCubit(this._connectivityService) : super(ConnectivityState.initial());

  void init() {
    _connectivityService.init(
      onConnectivityChanged: (result) {
        bool isInternetConnected = result.isNotEmpty && result.first != ConnectivityResult.none;
        emit(state.copyWith(isInternetConnected: isInternetConnected));
      },
    );
  }

  @override
  Future<void> close() {
    _connectivityService.updateListener((result) {
      emit(state.copyWith(isInternetConnected: result.isNotEmpty));
    });
    return super.close();
  }
}
